class NewHermes
  attr_reader :logger, :sell_price, :notifier
  attr_accessor :balance_usd, :balance_btc, :last_buy_usd, :profit_sum, :last_buy_price

  def initialize(logger, balance_usd, balance_btc)
    @logger = logger
    @balance_usd = balance_usd
    @balance_btc = balance_btc
    @profit_sum = 0.0
    @last_buy_price = 0.0
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
    self.last_buy_price = sell_price/AFTER_FEE
    self.balance_btc = AFTER_FEE*(balance_usd / sell_price)
    logger.info("Buy:  got #{"%0.5f" % balance_btc} for #{sell_price/AFTER_FEE} | -#{"%0.1f" % balance_usd} USD")
    self.balance_usd = 0.0
  end

  def sell!(sell_price)
    return unless balance_btc > 0
    self.balance_usd = AFTER_FEE*(balance_btc * sell_price)
    self.profit_sum += profit(sell_price)
    logger.info("Sell: got #{"%0.1f" % balance_usd} USD for #{"%0.1f" % (sell_price*AFTER_FEE)} | -#{"%0.5f" % balance_btc} BTC | Profit=#{profit(sell_price).round(1).traffic_light(0.0)} | Sum=#{profit_sum.round(1).traffic_light(0.0)}")
    self.balance_btc = 0.0
    self.last_buy_usd = 0.0
    self.last_buy_price = 0.0
  end

  def final_usd(close_prices)
    if balance_usd == 0.0
      (balance_btc / AFTER_FEE) * close_prices.last
    else
      balance_usd
    end
  end
end