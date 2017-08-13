class Captain

  attr_accessor :last_action, :balance, :orders, :balance_usd, :balance_btc

  def initialize
    @balance_usd = 100.0
    @profit_sum = @last_buy = @balance_btc = 0.0
    hermes.buy!(3237)
    fail if [:train, :production].exclude?(CONFIG[:mode].to_sym)
    @maxx = nil
  end

  def lead_the_way!
    if hermes.last_buy_price.nil? || hermes.last_buy_price == 0
      logger.info("No last_buy_price detected")
      return
    end

    refresh_data!

    if hermes.balance_btc > 0
      @maxx = [sell_price, (@maxx || 0), hermes.last_buy_price].max
    else
      @maxx = 0.0
    end

    logger.info("last_buy_price=#{"%0.1f" % hermes.last_buy_price} current_price=#{"%0.1f" % sell_price} maxx_threshold=#{"%0.1f" % maxx_threshold}")

    if hermes.balance_btc > 0 && sell_price < maxx_threshold
      hermes.sell!(sell_price)
      @maxx = 0.0
    end
  end

  def maxx_threshold
    @maxx && @maxx * CONFIG[:maxx_thresh_koef]
  end

  def minn_threshold
    @minn && @minn * CONFIG[:minn_thresh_koef]
  end

  def hermes
    @hermes ||= Hermes.new(logger, balance_usd, balance_btc)
  end

  def mode
    CONFIG[:mode]
  end

  def production?
    CONFIG[:mode] == :production
  end

  def train?
    CONFIG[:mode] == :train?
  end

  def logger
    @logger ||= begin
      res = Logger.new(BASE_PATH + CONFIG[:captain_log_path] + ".#{mode}")

      def res.info(msg)
        puts msg
        super
      end

      res
    end
  end

  def period
    300
  end

  def clear_redis!
    redis.keys("#{pair}:#{period}:*").each { |key| redis.del(key) }
  end

  def refresh_data!
    clear_redis!
    fill_close_prices!
    fill_indexes!
  end

  def pair
    "USDT_BTC"
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

  def fill_close_prices!
    self.orders = Poloniex::Client.order_book(pair)
    candles = Poloniex::Client.chart_data(pair, period: period, start_date: (Time.now-60*60*2).to_i)
    close = candles.map { |i| i["close"] }
    close.pop
    close << sell_orders.first.first
    redis.rpush("#{pair}:#{period}:close", close)
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