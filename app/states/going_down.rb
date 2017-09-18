module GoingDeep
  def buy!
    telegram_msg("Buying: #{hermes.buy!(sell_price)}")
    @minn = nil
    @unlock_at = nil
    # sleep 1
  end

  def check_buy?
    hermes.balance_usd > 0 && sell_price.round >= minn_threshold.round && @unlock_at > 100
  end
end