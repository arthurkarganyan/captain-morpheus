class NewHermes
  attr_reader :logger, :sell_price, :notifier, :pair, :poloniex_clazz, :redis
  attr_accessor :last_buy_usd, :profit_sum

  def initialize(logger, pair, poloniex_clazz, redis)
    @logger = logger
    @pair = pair
    @profit_sum = 0.0
    @poloniex_clazz = poloniex_clazz
    @redis = redis
  end

  def last_buy_price
    @last_buy_price ||= redis.get("hermes:last_buy_price").try(:to_f)
  end

  def last_buy_price=(x)
    redis.set("hermes:last_buy_price", x)
    @last_buy_price = x
  end

  def balances
    @balances ||= balances!
  end

  def balances!
    if CONFIG[:mode].to_sym == :production
      Balances.new(poloniex_clazz).balances!
    else
      @fake_balances ||= {"USDT" => 100.0, "BTC" => 0.0}
    end
  end

  def balance_usd=(usd)
    if CONFIG[:mode].to_sym != :production
      balances!["USDT"] = usd
    end
  end

  def balance_btc=(btc)
    if CONFIG[:mode].to_sym != :production
      balances!["BTC"] = btc
    end
  end

  def clear_balances!
    @balances = nil
  end

  def balance_usd
    balances[pair.split("_").first]
  end

  def balance_btc
    balances[pair.split("_").last]
  end

  def handle!
    yield
  end

  def profit(sell_price)
    return 0 unless last_buy_usd
    AFTER_FEE*(balance_btc * sell_price) - last_buy_usd
  end

  def buy!(sell_price)
    return unless balance_usd > 0
    self.last_buy_usd = balance_usd

    res = poloniex_clazz.buy(pair, sell_price, (balance_usd / sell_price))

    self.last_buy_price = sell_price
    self.balance_btc = AFTER_FEE*(balance_usd / sell_price)
    tmp = AFTER_FEE*(balance_usd / sell_price)
    logger.info("Buy:  got #{"%0.5f" % tmp} for #{sell_price/AFTER_FEE} | -#{"%0.2f" % balance_usd} USD")
    self.balance_usd = 0.0
    res
  end

  def sell!(sell_price)
    return unless balance_btc > 0
    self.balance_usd = AFTER_FEE*(balance_btc * sell_price)
    self.profit_sum += profit(sell_price)

    res = poloniex_clazz.sell(pair, sell_price, (balance_btc))

    logger.info("Sell: got #{"%0.1f" % balance_usd} USD for #{"%0.1f" % (sell_price*AFTER_FEE)} | -#{"%0.5f" % balance_btc} BTC | Profit=#{profit(sell_price).round(1).traffic_light(0.0)} | Sum=#{profit_sum.round(1).traffic_light(0.0)}")
    self.balance_btc = 0.0
    self.last_buy_usd = 0.0
    self.last_buy_price = 0.0

    res
  end

  def final_usd(close_prices)
    if balance_usd == 0.0
      (balance_btc / AFTER_FEE) * close_prices.last
    else
      balance_usd
    end
  end
end