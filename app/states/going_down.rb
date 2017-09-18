module GoingDeep
  def check_auto_buy?
    hermes.balance_usd > 0 && sell_price.round >= minn_threshold.round && @unlock_at > 100
  end

  def auto_buy!
    telegram_msg("Buying: #{hermes.buy!(sell_price)}")
    @minn = nil
    @unlock_at = nil
    # sleep 1
  end

  def handle_going_down
    @unlock_at += 1
    @minn = [sell_price, (@minn || 10**10)].min if (hermes.balance_usd > 0)

    add_buy_button
    log("minn_threshold=#{"%0.1f" % minn_threshold}")
  end

  def check_manual_buy?
    return false unless hermes.balances["USDT"] > 1
    last_msg = MorpheusResponder.telegram_redis.lrange("received_msgs:#{MorpheusResponder.instance.chat_id}", -1, -1).first
    return false unless last_msg
    last_msg.downcase!
    last_msg.start_with?("/buy") && last_msg[4..-1] == pair.split('_').last.downcase
  end

  def manual_buy!
    MorpheusResponder.telegram_redis.lpop("received_msgs:#{MorpheusResponder.instance.chat_id}")
    buy!
  end
end