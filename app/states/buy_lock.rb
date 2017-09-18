module BuyLock
  def check_unlock?
    current_rsi < 40.0
  end

  def unlock!
    @unlock_at = 0
  end

  def current_rsi
    rsi = Indicators::Data.new(chart_data_closes).calc(type: :rsi, params: 24).output
    rsi.last
  end

  def handle_buy_lock
    # add_buy_button
  end
end