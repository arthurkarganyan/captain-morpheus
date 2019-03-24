# require 'bundler'
# Bundler.require(:default)

require 'pry'
require 'redis'
require 'pp'
require 'colorize'
require 'active_support/all'
require 'gnuplot'
require_relative 'lib/chart_data'
require_relative 'lib/neuron'


$chart_data = ChartData.new(-4000..-1)

def sigmoid(x)
  1/(1+2.718281828459045**(-x))
end

task :test do
  Gnuplot.open do |gp|
    Gnuplot::Plot.new(gp) do |plot|

      plot.title "Array Plot Example"
      plot.data = [
        Gnuplot::DataSet.new($chart_data.specific("close")) do |ds|
          ds.with = "lines"
          ds.title = "close"
        end,
        Gnuplot::DataSet.new($chart_data.specific("12movingavg")) do |ds|
          ds.with = "lines"
          ds.title = "12movingavg"
        end,
        Gnuplot::DataSet.new($chart_data.specific("24movingavg")) do |ds|
          ds.with = "lines"
          ds.title = "24movingavg"
        end,
      ]
    end
  end
end

# INDICATORS = %w(rsi12 movingavg12 movingavg24 trend12 trend24)
INDICATORS = %w(rsi12 trend12 trend24)

def fast_plot(hash)
  Gnuplot.open do |gp|
    Gnuplot::Plot.new(gp) do |plot|

      # plot.title "Array Plot Example"
      plot.data = hash.map do |key, value|
        Gnuplot::DataSet.new(value) do |ds|
          ds.title = key
          ds.with = "lines"
          # ds.title = "24movingavg"
        end
      end
    end
  end
end

task :neuron_test do
  n = Neuron.new($chart_data.specific(*INDICATORS))
  best = n.find_best!
  successful = best.select { |i| i.first > START_USD }
  puts "Success rate [>#{START_USD} USD]: #{successful.size.to_f * 100.0/ best.size} %"
  p successful
  the_best_no = successful.last.last
  the_best_ary = n.run(the_best_no, true)
  buys = the_best_ary.map { |i| i.first == 1 ? 1 : 0 }
  sells = the_best_ary.map { |i| i.first == -1 ? 1 : 0 }
  fast_plot(rate: best.map { |i| i.first })
  fast_plot(close: $chart_data[:close],
            buys: buys.zip($chart_data[:close]).map { |i| i.first * i.last },
            sells: sells.zip($chart_data[:close]).map { |i| i.first * i.last },
            sum: the_best_ary.map { |i| i.last*1000 },
            threshold_plus: Array.new($chart_data.size) { n.rand_plus_threshold[the_best_no]*1000 },
            threshold_minus: Array.new($chart_data.size) { n.rand_minus_threshold[the_best_no]*1000 },
  )
  # binding.pry
end

task :c do
  binding.pry
end
