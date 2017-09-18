module GoingUp
  def sell!
    telegram_msg("Selling: #{hermes.sell!(sell_price)}")
    @maxx = 0.0
    @stepted_out = nil
  end

  def check_sell?
    hermes.balance_btc > 0 && (sell_price < maxx_threshold || current_rsi > 75.0) && sell_price > profit_point
  end

  def handle_going_up
    if hermes.last_buy_price.nil? || hermes.last_buy_price == 0
      Morpheus.logger.info("No last_buy_price detected")
      return
    end

    @maxx = (hermes.balance_btc > 0) ? [sell_price, (@maxx || 0), profit_point].max : 0.0

    if sell_price*AFTER_FEE > profit_point*1.002 && @stepted_out === nil
      @stepted_out = true
    end

    log("profit_point=#{"%0.1f" % profit_point} current_price=#{"%0.1f" % sell_price} maxx_threshold=#{"%0.1f" % maxx_threshold}")
  end

  def maxx_threshold
    # if @stepted_out
    #   [profit_point*1.002, @maxx && @maxx * CONFIG[:maxx_thresh_koef] || 0.0].max
    # else
    @maxx && @maxx * CONFIG[:maxx_thresh_koef]
    # end
  end
end