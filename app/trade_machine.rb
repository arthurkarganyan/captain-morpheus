class TradeMachine
  INITIAL_STATE = :buy_lock
  TRANSITIONS = {
    maximum_searching: {sell!: :buy_lock},
    buy_lock: {unlock!: :minimum_searching},
    minimum_searching: {buy!: :profit_point_waiting},
    profit_point_waiting: {reached_profit_point!: :maximum_searching,
                           emergency_sell!: :buy_lock}
  }

  STATES = TRANSITIONS.keys

  attr_reader :state, :hermes, :pair

  attr_accessor :orders

  STATES.each do |state|
    define_method(state) do
      state == @state
    end
  end

  def initialize(pair)
    @pair = pair
    @state = load_state
    @hermes = NewHermes.new(logger, 100.0, 0.0)
    @maxx = @minn = nil

    logger.info("created with state: #{state_color(@state)}")
  end

  def transit(to_state, action)
    to_state, action = to_state.to_sym, action.to_sym
    fail("Unknown state #{to_state}") unless STATES.include?(to_state)
    transition_found = false
    TRANSITIONS[state].each do |k, v|
      if v == to_state && k == action
        transition_found = true
        break
      end
    end

    unless transition_found
      fail("Transition not found: #{state} -> #{to_state} by method '#{action}'")
    end

    fail("'#{action}' not implemented") unless respond_to?(action, true)

    send(action)
    telegram_msg("Changed state from #{state_color(state)} -> #{state_color(to_state)}")
    @state = to_state
    redis.setex(redis_state_key, 1.hour.to_i, to_state) if mode == :production
  end

  def redis_state_key
    "trade_machine:#{pair}:state"
  end

  def load_state
    (redis.get(redis_state_key) || INITIAL_STATE).to_sym
  end

  def telegram_msg(msg)
    puts msg
  end

  def mode
    CONFIG[:mode].to_sym
  end

  def logger
    @logger ||= begin
      path = BASE_PATH + CONFIG[:captain_log_path] + ".#{mode}"
      puts "Log written to #{path}"
      res = Logger.new(path)

      def res.info(msg)
        puts msg
        super
      end

      res
    end
  end

  def run!
    refresh_data!
    send("handle_#{state}")

    TRANSITIONS[state].each do |k, v|
      return transit(v, k) if send("check_#{k.to_s.sub('!', '?')}")
    end

    @chart_data_closes = nil
  end

  def sell!
    hermes.sell!(sell_price)
    @maxx = 0.0
    @stepted_out = nil
  end

  def check_unlock?
    current_rsi < 40.0
  end

  def unlock!
    @unlock_at = 0
  end

  def buy!
    # p "sma: #{current_sma}"
    hermes.buy!(sell_price)
    @minn = nil
    @unlock_at = nil
    # sleep 1
  end

  attr_reader :stepted_out

  def handle_maximum_searching
    if hermes.last_buy_price.nil? || hermes.last_buy_price == 0
      logger.info("No last_buy_price detected")
      return
    end

    @maxx = (hermes.balance_btc > 0) ? [sell_price, (@maxx || 0), profit_point].max : 0.0

    if sell_price*AFTER_FEE > profit_point*1.002 && @stepted_out === nil
      @stepted_out = true
    end

    log("profit_point=#{"%0.1f" % profit_point} current_price=#{"%0.1f" % sell_price} maxx_threshold=#{"%0.1f" % maxx_threshold}")
  end

  def check_sell?
    hermes.balance_btc > 0 && (sell_price < maxx_threshold || current_rsi > 75.0) && sell_price > profit_point
  end

  def maxx_threshold
    # if @stepted_out
    #   [profit_point*1.002, @maxx && @maxx * CONFIG[:maxx_thresh_koef] || 0.0].max
    # else
    @maxx && @maxx * CONFIG[:maxx_thresh_koef]
    # end
  end

  def minn_threshold
    @minn && @minn / CONFIG[:minn_thresh_koef]
  end

  def reached_profit_point!
  end

  def handle_buy_lock

  end

  def state_color(state)
    h={maximum_searching: :green,
       buy_lock: :blue,
       minimum_searching: :red,
       profit_point_waiting: :magenta}

    state.to_s.colorize(h[state])
  end

  def log(msg)
    return
    general_msg = "#{state_color(state)} | "
    general_msg << "current_price=#{"%0.1f" % sell_price} "
    general_msg << "rsi=#{"%0.1f" % current_rsi}"
    logger.info("#{general_msg} #{msg}")
  end

  def handle_minimum_searching
    @unlock_at += 1
    @minn = [sell_price, (@minn || 10**10)].min if (hermes.balance_usd > 0)

    log("minn_threshold=#{"%0.1f" % minn_threshold}")
  end

  def check_reached_profit_point?
    sell_price > profit_point
  end

  def profit_point
    hermes.last_buy_price / AFTER_FEE
  end

  def check_emergency_sell?
    false
  end

  def handle_profit_point_waiting
    log("")
  end

  def check_buy?
    hermes.balance_usd > 0 && sell_price.round >= minn_threshold.round && @unlock_at > 100
  end

  def current_rsi
    rsi = Indicators::Data.new(chart_data_closes).calc(type: :rsi, params: 24).output
    rsi.last
  end

  def current_sma
    sma = Indicators::Data.new(chart_data_closes).calc(type: :sma, params: 48).output
    sma.last
  end

  def period
    300 #* 12 * 2
  end

  def thresh_koef
    CONFIG[:thresh_koef]
  end

  def clear_redis!
    redis.keys("#{pair}:#{period}:*").each { |key| redis.del(key) }
  end

  def refresh_data!
    clear_redis!
    fill_close_prices!
    # fill_indexes!
  end

  def sell_price
    sell_orders.first.first
  end

  def buy_price
    buy_orders.first.first
  end

  def sell_orders
    orders[:sells]
  end

  def buy_orders
    orders[:buys]
  end

  def poloniex_client_clazz
    if mode.to_sym == :production
      Poloniex::Client
    else
      FakePoloniex
    end
  end

  def chart_data
    poloniex_client_clazz.chart_data(pair, period: period, start_date: (Time.now-period*64).to_i)
  end

  def chart_data_closes
    return @chart_data_closes if @chart_data_closes
    @chart_data_closes = chart_data.map { |i| i["close"] }
    @chart_data_closes.pop
    @chart_data_closes << sell_orders.first.first
    @chart_data_closes
  end

  def fill_close_prices!
    self.orders = poloniex_client_clazz.order_book(pair)
    redis.rpush("#{pair}:#{period}:close", chart_data_closes)
  end

  def fill_indexes!
    folder = `pwd`.chomp.split('/')[0..-2].join("/") + '/indexer'
    res = `INDEXER_REDIS_DB=#{redis_db_no} ~/.virtualenvs/indexer/bin/python #{folder}/main.py`
    fail("Something went wrong with indexer!") unless res.chomp == 'Done!'
  end

  def redis
    @redis ||= Redis.new(db: redis_db_no)
  end

  def redis_db_no
    CONFIG[:captain_redis_db]
  end
end
