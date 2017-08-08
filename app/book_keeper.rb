class BookKeeper # Hermes Conrad
  attr_reader :logger

  def initialize(logger)
    @logger = logger
  end

  def buy!
    self.last_buy = balance_usd
    self.balance_btc = AFTER_FEE*(balance_usd / sell_price)
    logger.info("Buy:  got #{balance_btc} for #{sell_price/AFTER_FEE} | #{balance_usd} USD Disappeared")
    self.balance_usd = 0.0

    self.last_action = :buy
    notifier && notifier.notify!
  end

  def sell!
    self.balance_usd = AFTER_FEE*(balance_btc * sell_price)
    profit = (balance_usd - last_buy)
    self.profit_sum += profit
    logger.info("Sell: got #{balance_usd} for #{sell_price*AFTER_FEE} | #{balance_btc} BTC Disappeared | Profit = #{profit.traffic_light(last_buy)} | Profit sum = #{profit_sum.traffic_light(0.0)}")
    self.balance_btc = 0.0
    self.last_buy = 0.0

    self.last_action = :sell
    notifier && notifier.notify!
  end
end