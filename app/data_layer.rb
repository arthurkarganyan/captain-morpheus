class DataLayer
  attr_accessor :orders

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

  def chart_data
    Morpheus.poloniex_client_clazz.chart_data(pair, period: period, start_date: (Time.now-period*64).to_i)
  end

  def chart_data_closes
    return @chart_data_closes if @chart_data_closes
    @chart_data_closes = chart_data.map { |i| i["close"] }
    @chart_data_closes.pop
    @chart_data_closes << sell_orders.first.first
    @chart_data_closes
  end

  def fill_close_prices!
    self.orders = Morpheus.poloniex_client_clazz.order_book(pair)
    Morpheus.redis.rpush("#{pair}:#{period}:close", chart_data_closes)
  end

  def clear_redis!
    Morpheus.redis.keys("#{pair}:#{period}:*").each { |key| redis.del(key) }
  end

  def refresh_data!
    clear_redis!
    fill_close_prices!
    @chart_data_closes = nil
  end
end