class TradeMachine
  INITIAL_STATE = :buy_lock
  TRANSITIONS = {
    maximum_searching: {sell!: :buy_lock},
    buy_lock: {unlock!: :minimum_searching,
               manual_buy!: :profit_point_waiting},
    minimum_searching: {buy!: :profit_point_waiting,
                        manual_buy!: :profit_point_waiting},
    profit_point_waiting: {reached_profit_point!: :maximum_searching,
                           emergency_sell!: :buy_lock}
  }

  STATES = TRANSITIONS.keys

  attr_reader :state, :hermes, :pair, :telegram_options

  attr_accessor :orders

  STATES.each do |state|
    define_method(state) do
      state == @state
    end
  end

  def initialize(pair)
    @pair = pair
    @state = load_state
    @hermes = NewHermes.new(logger, pair, poloniex_client_clazz, redis)
    @maxx = @minn = nil
    @telegram_options = []

    a = "[#{self.class}:#{pair}]"
    logger.info("#{a} created with state: #{state_color(@state)}")
    telegram_msg("#{a} created with state: #{@state}")
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
    logger.info("Changed state from #{state_color(state)} -> #{state_color(to_state)}")
    telegram_msg("Changed state from #{state} -> #{to_state}")
    @state = to_state
    redis.set(redis_state_key, to_state) if mode == :production
  end

  def redis_state_key
    "trade_machine:#{pair}:state"
  end

  def load_state
    (redis.get(redis_state_key) || INITIAL_STATE).to_sym
  end

  def telegram_msg(msg)
    Responder.current.reply(msg)
  end

  def mode
    CONFIG[:mode].to_sym
  end

  def logger
    @logger ||= begin
      path = BASE_PATH + CONFIG[:captain_log_path] + '.' + pair + ".#{mode}"
      puts "Log written to #{path}"
      res = Logger.new(path)

      def res.info(msg)
        puts msg
        super
      end

      res
    end
  end

  def last_msg
    Responder.telegram_redis.lrange("received_msgs:#{Responder.current.chat_id}", -1, -1).first
  end

  def drop_last_msg
    Responder.telegram_redis.lpop("received_msgs:#{Responder.current.chat_id}")
  end

  def handle_telegram
    cmds = {
      '/debug' => lambda { binding.pry },
      '/lastbuy' => lambda { telegram_msg(hermes.last_buy_price.try(:round, 2) || "no last buy") },
      '/state' => lambda { telegram_msg(state) },
      '/buyprice' => lambda { telegram_msg(buy_price.round(2)) },
      '/sellprice' => lambda { telegram_msg(sell_price.round(2)) },
      '/changes' => lambda { telegram_msg(Changer.new(poloniex_client_clazz, pair).changes.to_s) },
      '/profitpoint' => lambda { telegram_msg(profit_point) },
      '/info' => lambda do
        telegram_msg({"buy_price" => buy_price.round(2),
                      "sell_price" => sell_price.round(2),
                      "profit_point" => profit_point.try(:round, 2) || "no profit point",
                      "last_buy_price" => hermes.last_buy_price.try(:round, 2) || "no last buy"}.frmt)
      end,
      '/balances' => lambda { telegram_msg(Balances.new(poloniex_client_clazz).balances!.frmt) },
      '/help' => lambda do
        buttons = cmds.keys.each_slice(3).map do |i|
          i.map { |j| Telegram::Bot::Types::InlineKeyboardButton.new(text: j, callback_data: j)}
        end
        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
        Responder.current.reply("Commands:", markup)
      end
    }
    return unless last_msg
    unless cmds[last_msg]
      l = cmds['/help']
      drop_last_msg
      l.call
      return
    end

    logger.info("Received cmd: #{last_msg}")
    l = cmds[last_msg]
    drop_last_msg
    l.call
  end

  def run!
    handle_telegram
    refresh_data!
    send("handle_#{state}")

    TRANSITIONS[state].each do |k, v|
      return transit(v, k) if send("check_#{k.to_s.sub('!', '?')}")
    end

    @chart_data_closes = nil
  end

  def sell!
    telegram_msg("Selling: #{hermes.sell!(sell_price)}")
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
    telegram_msg("Buying: #{hermes.buy!(sell_price)}")
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

  def check_manual_buy?
    return false unless hermes.balances["USDT"] > 1
    last_msg = Responder.telegram_redis.lrange("received_msgs:#{Responder.current.chat_id}", -1, -1).first
    return false unless last_msg
    last_msg.downcase!
    last_msg.start_with?("/buy") && last_msg[4..-1] == pair.split('_').last.downcase
  end

  def manual_buy!
    Responder.telegram_redis.lpop("received_msgs:#{Responder.current.chat_id}")
    buy!
  end

  def reached_profit_point!
  end

  def handle_buy_lock
    add_buy_button
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

  def add_buy_button
    @telegram_options = ["/buy#{pair.split("_").last.downcase}"]
  end

  def handle_minimum_searching
    @unlock_at += 1
    @minn = [sell_price, (@minn || 10**10)].min if (hermes.balance_usd > 0)

    add_buy_button
    log("minn_threshold=#{"%0.1f" % minn_threshold}")
  end

  def check_reached_profit_point?
    buy_price > profit_point
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
    hermes.clear_balances!
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
