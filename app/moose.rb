class Moose
  def profit_on_range(range, graph = false, thresh_koef)
    close_prices = ChartData.new(range)[:close]

    logger =Logger.new(STDOUT)
    # logger.level = Logger::WARN
    hermes = Hermes.new(logger, 100.0, 0.0, nil, range)

    ideal_buys, ideal_sells = Rockefeller.ideal_buys_and_sells(close_prices)
    maxx = nil
    minn = nil
    max_thresholds = []
    sells = [[], []]
    buys = [[], []]

    ideal_buys = [[211, 446, 885, 1019]]
    (close_prices.size-1).times do |i|
      if hermes.balance_btc > 0
        maxx = [close_prices[i]*AFTER_FEE, (maxx || 0), hermes.last_buy_price].max
      else
        maxx = 0.0
      end
      maxx_threshold = maxx * thresh_koef

      if hermes.balance_usd > 0 && ideal_buys.first.include?(i)
        hermes.buy!(close_prices[i])
        buys.first << i
        buys.last << close_prices[i].lg
      elsif hermes.balance_btc > 0 && (close_prices[i] < maxx_threshold)# && close_prices[i]*AFTER_FEE > hermes.last_buy_price/AFTER_FEE#ideal_sells.first.include?(i)
        hermes.sell!(close_prices[i])
        sells.first << i
        sells.last << close_prices[i].lg
        maxx = 0.0
      end

      max_thresholds << maxx_threshold
    end

    balance_usd = hermes.final_usd(close_prices)
    max_usd = max_usd(close_prices)

    real_profit_str = balance_usd.usd.colorize(balance_usd > 100.0 ? :green : :red)
    balance_usd_str = max_usd.usd.colorize(:yellow)
    puts "Profit #{"[#{range}]".colorize(:blue)} real/possible: #{real_profit_str}/#{balance_usd_str}"

    if graph
      Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|
          plot.data = [
            Gnuplot::DataSet.new(buys) { |ds|
              ds.with = "impulse"
              ds.title = "buys"
            },

            Gnuplot::DataSet.new(sells) { |ds|
              ds.with = "impulse"
              ds.title = "sells"
            },

            Gnuplot::DataSet.new(close_prices.map { |i| i * AFTER_FEE }.map(&:lg)) { |ds|
              ds.with = "lines"
              ds.title = "sell price"
            },

            Gnuplot::DataSet.new(close_prices.map { |i| i / AFTER_FEE }.map(&:lg)) { |ds|
              ds.with = "lines"
              ds.title = "buy price"
            },

            Gnuplot::DataSet.new(max_thresholds.map(&:lg)) { |ds|
              ds.with = "lines"
              ds.title = "threshold"
            }
          ]
        end
      end
    end

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
end