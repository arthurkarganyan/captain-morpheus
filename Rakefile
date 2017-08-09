require_relative 'load_config'

task :c do
  binding.pry
end

task :long do
  range = -365..-1
  chart_data = ChartData.new(range, 1.day)


  # set title "candlesticks showing both states of open/close"
  # set style fill empty
  # set boxwidth 0.2
  # plot 'candlesticks.dat' using 1:(int($0)%3?$3:$5):2:6:(int($0)%3?$5:$3) with candlesticks title "open < close", \
  # NaN with boxes lt 1 fs solid 1 title "close < open"

  ary = [
    ['2014-01-01 17:00:00', 1.376150, 1.376550, 1.374020, 1.375990],
    ['2014-01-01 18:00:00', 1.376100, 1.377340, 1.375980, 1.376520],
    ['2014-01-01 19:00:00', 1.376440, 1.376870, 1.375780, 1.375860],
    ['2014-01-01 20:00:00', 1.375850, 1.376470, 1.375000, 1.376280],
    ['2014-01-01 21:00:00', 1.376270, 1.376720, 1.375970, 1.376530],
    ['2014-01-01 22:00:00', 1.376550, 1.377440, 1.376270, 1.376530],
    ['2014-01-01 23:00:00', 1.376540, 1.376540, 1.374390, 1.374520],
    ['2014-01-02 00:00:00', 1.374500, 1.375790, 1.374380, 1.375660],
    ['2014-01-02 01:00:00', 1.375630, 1.375740, 1.374610, 1.375000],
    ['2014-01-02 02:00:00', 1.374980, 1.375270, 1.372480, 1.373100]
  ]


  # set xdata time
  # set timefmt"%Y-%m-%d %H:%M:%S"
  # set datafile separator ","
  #
  # set palette defined (-1 'red', 1 'green')
  # set cbrange [-1:1]
  # unset colorbox
  #
  # set style fill solid noborder
  #
  # plot '201404_EURUSD_Hourly.csv' using 1:2:4:3:5:($5 < $2 ? -1 : 1)  notitle with candlesticks palette
  #

  pair = "USDT_LTC"
  cp = CandlePicker.new('2017-04-01', '2017-09-01', 1.day.to_i, pair)
  cp.polo_to_csv

  cmds = <<-HEREDOC
  set title '#{pair}'
  set xdata time
  set timefmt'%Y-%m-%d'
  set datafile separator ','

  set palette defined (-1 'red', 1 'green')
  set cbrange [-1:1]
  unset colorbox

  set style fill solid noborder

  plot '#{cp.csv_path}' using 1:4:3:2:5:(\\$5 < \\$4 ? -1 : 1)  notitle with candlesticks palette
  HEREDOC

  # plot '201404_EURUSD_Hourly.csv' using 1:2:4:3:5:(\\$5 < \\$2 ? -1 : 1)  notitle with candlesticks palette
  # date,high,low,open,close,volume,quoteVolume,weightedAverage
  # 1:open:low:high:close:(close < open)
  # 1:4:3:2:5 (\\$5 < )
  # plot 'USDT_BTC_1451606400_1483228800_86400.csv' using 1:2:4:3:5:(\\$5 < \\$2 ? -1 : 1)  notitle with candlesticks palette
  # 5 - close
  # 2 - open
  # 3 - high
  # 4 - low
  # open, high, low, close
  `gnuplot -p -e "#{cmds.split("\n").join(";")}"`



  # Gnuplot.open do |gp|
  #   Gnuplot::Plot.new(gp) do |plot|
  #     plot.xdata :time
  #     plot.timefmt "'%Y-%m-%d %H:%M:%S'"
  #     plot.datafile 'separator ","'
  #
  #     plot.palette "defined (-1 'red', 1 'green')"
  #     plot.cbrange "[-1 : 1]"
  #     plot.unset "colorbox"
  #     plot.set "style fill solid noborder"
  #     #
  #
  #     # plot.xrange "[-10:10]"
  #     # plot.title "Sin Wave Example"
  #     # plot.ylabel "x"
  #     # plot.xlabel "sin(x)"
  #     #
  #     # x = (0..50).collect { |v| v.to_f }
  #     # y = x.collect { |v| v ** 2 }
  #     #
  #     # plot.data = [
  #     #   Gnuplot::DataSet.new([x, y]) { |ds|
  #     #     ds.with = "candlesticks"
  #     #     ds.title = "Array data"
  #     #   }
  #     # ]
  #
  #     plot.data "'201404_EURUSD_Hourly.csv' using 1:2:4:3:5:($5 < $2 ? -1 : 1)  notitle with candlesticks palette"
  #   end
  # end


  # Gnuplot.open do |gp|
  #   Gnuplot::Plot.new(gp) do |plot|
  #
  #     plot.xrange "[-10:10]"
  #     plot.title "Sin Wave Example"
  #     plot.ylabel "x"
  #     plot.xlabel "sin(x)"
  #
  #     x = (0..50).collect { |v| v.to_f }
  #     y = x.collect { |v| v ** 2 }
  #
  #     plot.data = [
  #       Gnuplot::DataSet.new([x, y]) { |ds|
  #         ds.with = "candlesticks"
  #         ds.title = "Array data"
  #       }
  #     ]
  #   end
  # end
  # binding.pry
end

task :lead_the_way do
  c = Captain.new

  loop do
    c.lead_the_way!
    sleep 60
  end
end

task :zhdun_graph do

end

task :zhdun do
  100.times do |i|
    z = Zhdun.new(-20000..-1, i*0.001);
    z.normalized_distances;
    p [z.profit.avg, z.normalized_distances.avg, z.normalized_distances.median]
  end
end

task :mavg do
  redis = Redis.new(db: CONFIG[:train_redis_db])

  redis.del("USDT_BTC:300:mavg12coef")
  redis.del("USDT_BTC:300:mavg24coef")

  close_ary = redis.lrange("USDT_BTC:300:close", 0, -1).map(&:to_f)
  mavg12_ary = redis.lrange("USDT_BTC:300:movingavg12", 0, -1).map(&:to_f)
  mavg24_ary = redis.lrange("USDT_BTC:300:movingavg24", 0, -1).map(&:to_f)

  mavg12coef = []
  mavg24coef = []
  (close_ary.size-1).times do |i|
    mavg12coef << (close_ary[i] / mavg12_ary[i]) - 1
    mavg24coef << (close_ary[i] / mavg24_ary[i]) - 1
  end

  redis.lpush("USDT_BTC:300:mavg12coef", mavg12coef)
  redis.lpush("USDT_BTC:300:mavg24coef", mavg24coef)
end

task :magnus_test do
  n = Magnus.new($chart_data.specific(*INDICATORS))
  best = n.find_best!
  successful = best.select { |i| i.first > START_USD }
  puts "Success rate [>#{START_USD} USD]: #{successful.size.to_f * 100.0/ best.size} %"
  p successful
  the_best_no = successful.last.last
  the_best_ary = n.run(the_best_no, true)
  buys = the_best_ary.map { |i| i.first == 1 ? 1 : 0 }
  sells = the_best_ary.map { |i| i.first == -1 ? 1 : 0 }
  # fast_plot(rate: best.map { |i| i.first })
  # fast_plot(close: $chart_data[:close],
  #           buys: buys.zip($chart_data[:close]).map { |i| i.first * i.last },
  #           sells: sells.zip($chart_data[:close]).map { |i| i.first * i.last },
  #           sum: the_best_ary.map { |i| i.last*1000 },
  #           threshold_plus: Array.new($chart_data.size) { n.rand_plus_threshold[the_best_no]*1000 },
  #           threshold_minus: Array.new($chart_data.size) { n.rand_minus_threshold[the_best_no]*1000 },
  # )
end

def close_plot(range)
  chart_data = ChartData.new(range)
  close_price = chart_data[:movingavg24]

  sma = Indicators::Data.new(close_price).calc(type: :sma, params: 50).output.map { |i| i && i.round(1) }

  fast_plot(ask: chart_data[:close].map { |i| Math.log(i.ask) },
            bid: chart_data[:close].map { |i| Math.log(i.bid) },
            trend12: chart_data[:trend12].map { |i| 5.0+Math.log(20.0+i/2) },
            trend24: chart_data[:trend24].map { |i| 5.0+Math.log(20.0+i/2) },
            trend: chart_data[:trend24].map { |i| 5.0 + Math.log(20.0) },
            sma: sma.map { |i| i && Math.log(i) || 5.0 + Math.log(20.0) },
            mavg24: chart_data[:movingavg24].map { |i| Math.log(i) },
            mavg12: chart_data[:movingavg12].map { |i| Math.log(i) })
end

task :close_plot do
  close_plot(-1000..-1)
end

task :check_best do
  leo = Leonardo.best

  size = 600
  start = -10000
  # 4.times do
  #   range = Range.new(start, start+=size)
  #   profit = leo.profit_on_range(range)
  # end
  leo.profit_on_range(-10000..-8000)

end

task :train_leo do
  train_range = -3000..-2950

  trained_leos = Array.new(10) do
    Leonardo.new(train_range)
  end.select do |leo|
    trained_profit = leo.profit_on_range(train_range)
    leo.initial_possibility_used = (trained_profit.first-100.0)/(trained_profit.last-100.0)
    leo.initial_possibility_used > 0.3
  end

  trained_leos[0].profit_on_range(-10000..-1).first

  size = 100
  winners = []

  INTERVALS = 20
  trained_leos.each do |leo|
    possibilities = []
    start = -2950
    INTERVALS.times do
      range = Range.new(start, start+=size)
      profit = leo.profit_on_range(range)
      possibilities << [(profit.first-100.0)/(profit.last-100.0), leo.initial_possibility_used]
      # possibility_used = leo.profit_on_range(Range.new(start, start+=size))
      # possibility_used
    end

    leo.check_score = possibilities.map { |i| i.first }.inject(:+) / INTERVALS
    if leo.check_score > 0.05
      winners << leo
    end
  end

  winners.each do |leo|
    leo.compatative_profit = leo.profit_on_range(-10000..-1).first
  end

  winners.sort_by! { |leo| leo.compatative_profit }.reverse!
  winners.each do |leo|
    p [leo.initial_possibility_used, leo.check_score, leo.compatative_profit]
  end

  winners.first.save!
end
