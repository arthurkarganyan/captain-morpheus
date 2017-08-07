module Competitor
  def generate_buys(range)
    fail NotImplementedError
  end

  def generate_sells(range)
    fail NotImplementedError
  end

  # TODO can be optimized

  def profit_on_range(range, graph = false)
    balance_usd = 100.0
    balance_btc = 0.0

    close_prices = ChartData.new(range)[:close]

    buys = generate_buys(range)
    sells = generate_sells(range)

    last_buy = 0.0
    sum_profit = 0.0

    close_prices.size.times do |i|
      if buys[i] == 1 && sells[i] == 0 && balance_usd > 0.0
        last_buy = balance_usd
        balance_btc = (balance_usd * AFTER_FEE) / close_prices[i]
        balance_usd = 0.0
        puts "#{i}, buy=#{(close_prices[i]/AFTER_FEE).round(1)} #{balance_usd.round(2)}, #{balance_btc.round(5)}"
      elsif buys[i] == 0 && sells[i] == 1 && balance_btc > 0.0
        balance_usd = (balance_btc / AFTER_FEE) * close_prices[i]
        profit = balance_usd - last_buy
        sum_profit += profit
        balance_btc = 0.0

        profit = profit.round(1)
        profit = profit > 0 ? profit.to_s.colorize(:green) : profit.to_s.colorize(:red)
        puts "#{i}, sell=#{(close_prices[i]*AFTER_FEE).round(1)}, #{balance_usd.round(2)}, #{balance_btc.round(5)}, profit=#{profit}"
      end
    end

    # puts "balance usd=#{balance_usd} , balance_btc=#{balance_btc}"
    # puts "sum_profit=#{sum_profit}"
    balance_usd = (balance_btc / AFTER_FEE) * close_prices.last if balance_usd == 0.0

    buys_graph = [(0..buys.size).to_a, []]
    buys.size.times { |i| buys_graph.last << buys[i]*close_prices[i] }
    sells_graph = [(0..sells.size).to_a, []]
    sells.size.times { |i| sells_graph.last << sells[i]*close_prices[i] }

    ideal_buys, ideal_sells = Rockefeller.ideal_buys_and_sells(close_prices)

    if graph
      Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|

          plot.data << Gnuplot::DataSet.new(close_prices) do |ds|
            ds.with = "lines"
            ds.title = "close"
          end

          # plot.data << Gnuplot::DataSet.new(chart_data[:rsi12]) do |ds|
          #   ds.with = "lines"
          #   ds.title = "RSI12"
          # end

          # plot.data << Gnuplot::DataSet.new(close_prices.map { |i| i * AFTER_FEE }) do |ds|
          #   ds.with = "lines"
          #   ds.title = "close_sell_with_fee"
          # end
          #
          # plot.data << Gnuplot::DataSet.new(close_prices.map { |i| i / AFTER_FEE }) do |ds|
          #   ds.with = "lines"
          #   ds.title = "close_buy_with_fee"
          # end

          plot.data << Gnuplot::DataSet.new(buys_graph) do |ds|
            ds.with = "impulse"
            ds.title = "buys"
          end

          plot.data << Gnuplot::DataSet.new(sells_graph) do |ds|
            ds.with = "impulse"
            ds.title = "sells"
          end

          plot.data << Gnuplot::DataSet.new(ideal_buys) do |ds|
            ds.with = "impulse"
            ds.title = "ideal buys"
          end

          plot.data << Gnuplot::DataSet.new(ideal_sells) do |ds|
            ds.with = "impulse"
            ds.title = "ideal sells"
          end
        end
      end
    end

    real_profit = balance_usd
    balance_usd = 100.0
    balance_btc = 0.0

    buys = []
    sells = []

    ideal_buys, ideal_sells = ideal_buys.last, ideal_sells.last

    ideal_buys.size.times do |i|
      balance_usd *= AFTER_FEE * AFTER_FEE * (ideal_sells[i]/ideal_buys[i])
    end

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

    range_str = "[#{range}]".colorize(:blue)
    real_profit_color = real_profit > 100.0 ? :green : :red
    real_profit_str = "#{real_profit.round(1)} USD".colorize(real_profit_color)
    balance_usd_str = "#{balance_usd.round(1)} USD".colorize(:yellow)
    puts "Profit #{range_str} real/possible: #{real_profit_str}/#{balance_usd_str}"

    [real_profit, balance_usd]
  end
end