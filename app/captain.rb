class Captain

  attr_accessor :last_action, :balance, :orders, :balance_usd, :balance_btc, :last_buy, :profit_sum

  def initialize
    @balance_usd = 100.0
    @profit_sum = @last_buy = @balance_btc = 0.0
  end

  def leo
    @leo ||= Leonardo.best
  end

  def lead_the_way!
    refresh_data!

    # TODO round remove?
    output_buy = NetTrainer.forward_propagate(leo.buy_net, net_input)
    output_sell = NetTrainer.forward_propagate(leo.sell_net, net_input)

    str = "#{"%0.3f" % (sell_price*AFTER_FEE)} | #{"%0.3f" % (sell_price/AFTER_FEE)} | buy=#{output_buy.round(1)} | sell=#{output_sell.round(1)} | "
    if output_buy.round == 1
      if balance_usd > 0.0
        logger.info(str + "Decided to buy")
        buy!
      else
        logger.info(str + "Decided to buy but there is no USD")
      end
    elsif output_sell.round == 1
      if balance_btc > 0.0
        logger.info(str + "Decided to sell")
        sell!
      else
        logger.info(str + "Decided to sell but there is no BTC")
      end
    else
      logger.info(str + "Decided to hold")
    end
  end

  def net_input
    Leonardo.normalize_indicators(
      redis.lrange("#{pair}:#{period}:rsi12", -1, -1).first.to_f,
      redis.lrange("#{pair}:#{period}:trend12", -1, -1).first.to_f,
      redis.lrange("#{pair}:#{period}:trend24", -1, -1).first.to_f
    )
  end

  def logger
    @logger ||= begin
      res = Logger.new(BASE_PATH + CONFIG[:captain_log_path])

      def res.info(msg)
        puts msg
        super
      end

      res
    end
  end

  def buy!
    self.last_buy = balance_usd

    self.balance_btc = AFTER_FEE*(balance_usd / sell_price)
    logger.info("Buy:  got #{balance_btc} for #{sell_price/AFTER_FEE} | #{balance_usd} USD Disappeared")
    self.balance_usd = 0.0

    self.last_action = :buy
    `cvlc ~/Dropbox/Sounds/beep18.mp3 --play-and-exit`
  end

  def sell!
    self.balance_usd = AFTER_FEE*(balance_btc * sell_price)
    profit = (balance_usd - last_buy)
    self.profit_sum += profit
    logger.info("Sell: got #{balance_usd} for #{sell_price*AFTER_FEE} | #{balance_btc} BTC Disappeared | Profit = #{profit.traffic_light(last_buy)} | Profit sum = #{profit_sum.traffic_light(0.0)}")
    self.balance_btc = 0.0
    self.last_buy = 0.0

    self.last_action = :sell
    `cvlc ~/Dropbox/Sounds/beep18.mp3 --play-and-exit`
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