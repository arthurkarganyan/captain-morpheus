module Competitor
  def generate_buys(range)
    fail NotImplementedError
  end

  def generate_sells(range)
    fail NotImplementedError
  end

  # TODO can be optimized

  def profit_on_range(range, graph = false)
    close_prices = ChartData.new(range)[:close]

    buys = generate_buys(range)
    sells = generate_sells(range)

    logger =Logger.new(STDOUT)
    # logger.level = Logger::WARN
    book_keeper = Hermes.new(logger, 100.0, 0.0, nil, range)

    (close_prices.size-1).times do |i|
      book_keeper.handle!(close_prices[i], buys[i], sells[i], i)
    end

    balance_usd = book_keeper.final_usd(close_prices)
    max_usd = max_usd(close_prices)

    real_profit_str = balance_usd.usd.colorize(balance_usd > 100.0 ? :green : :red)
    balance_usd_str = max_usd.usd.colorize(:yellow)
    puts "Profit #{"[#{range}]".colorize(:blue)} real/possible: #{real_profit_str}/#{balance_usd_str}"

    [balance_usd, max_usd]
  end

  def max_usd(close_prices)
    balance_usd = 100.0
    balance_btc = 0.0

    buys = []
    sells = []

    ideal_buys, ideal_sells = Rockefeller.ideal_buys_and_sells(close_prices)
    ideal_buys, ideal_sells = ideal_buys.last, ideal_sells.last

    ideal_buys.size.times do |i|
      balance_usd *= AFTER_FEE * AFTER_FEE * (ideal_sells[i]/ideal_buys[i])
    end

    balance_usd
  end

  # def usd_at(p_ary, n=(p_ary.size - 1))
  #   fail if n%2!=1 || n > p_ary.size
  #   return 1.0 if n == -1
  #   increase = p_ary[n]/p_ary[n-1]
  #   # p [n, p_ary[n], p_ary[n-1], p_ary[n] - p_ary[n-1], increase]
  #   increase*usd_at(p_ary, n-2)
  # end
end

# if graph
#   buys_graph = [(0..buys.size).to_a, []]
#   buys.size.times { |i| buys_graph.last << buys[i]*close_prices[i] }
#   sells_graph = [(0..sells.size).to_a, []]
#   sells.size.times { |i| sells_graph.last << sells[i]*close_prices[i] }
#   Gnuplot.open do |gp|
#     Gnuplot::Plot.new(gp) do |plot|
#
#       plot.data << Gnuplot::DataSet.new(close_prices) do |ds|
#         ds.with = "lines"
#         ds.title = "close"
#       end
#
#       # plot.data << Gnuplot::DataSet.new(chart_data[:rsi12]) do |ds|
#       #   ds.with = "lines"
#       #   ds.title = "RSI12"
#       # end
#
#       # plot.data << Gnuplot::DataSet.new(close_prices.map { |i| i * AFTER_FEE }) do |ds|
#       #   ds.with = "lines"
#       #   ds.title = "close_sell_with_fee"
#       # end
#       #
#       # plot.data << Gnuplot::DataSet.new(close_prices.map { |i| i / AFTER_FEE }) do |ds|
#       #   ds.with = "lines"
#       #   ds.title = "close_buy_with_fee"
#       # end
#
#       plot.data << Gnuplot::DataSet.new(buys_graph) do |ds|
#         ds.with = "impulse"
#         ds.title = "buys"
#       end
#
#       plot.data << Gnuplot::DataSet.new(sells_graph) do |ds|
#         ds.with = "impulse"
#         ds.title = "sells"
#       end
#
#       plot.data << Gnuplot::DataSet.new(ideal_buys) do |ds|
#         ds.with = "impulse"
#         ds.title = "ideal buys"
#       end
#
#       plot.data << Gnuplot::DataSet.new(ideal_sells) do |ds|
#         ds.with = "impulse"
#         ds.title = "ideal sells"
#       end
#     end
#   end
# end


# range.size.times do |i|
#   buys << ideal_buys.first.include?(i) ? 1 : 0
#   sells << ideal_sells.first.include?(i) ? 1 : 0
# end
#
# close_prices.size.times do |i|
#   if buys[i] == 1 && sells[i] == 0 && balance_usd > 0.0
#     balance_btc = (balance_usd * AFTER_FEE) / close_prices[i]
#     balance_usd = 0.0
#   end
#
#   if buys[i] == 0 && sells[i] == 1 && balance_btc > 0.0
#     balance_usd = (balance_btc / AFTER_FEE) * close_prices[i]
#     balance_btc = 0.0
#   end
# end
#
# balance_usd = (balance_btc / AFTER_FEE) * close_prices.last if balance_usd == 0.0
