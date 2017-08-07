require 'bundler'
Bundler.require(:default)
require 'active_support/all'

require_relative 'app/captain'
require_relative 'load_config'
require_relative 'lib/chart_data'
require_relative 'lib/competitor'
require_relative 'lib/magnus'
require_relative 'lib/leonardo'
require_relative 'lib/rockefeller'
require_relative 'lib/net_trainer'
require_relative 'lib/plot_utils'

task :c do
  binding.pry
end

task :refresh_data do

end



def sigmoid(x)
  1/(1+2.718281828459045**(-x))
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

task :c do
  binding.pry
end

# def usd_at(p_ary, n=(p_ary.size - 1))
#   fail if n%2!=1 || n > p_ary.size
#   return 1.0 if n == -1
#   increase = p_ary[n]/p_ary[n-1]
#   # p [n, p_ary[n], p_ary[n-1], p_ary[n] - p_ary[n-1], increase]
#   increase*usd_at(p_ary, n-2)
# end

task :compete_leonardo do
  train_range = -3000..-2950

  trained_leos = Array.new(20) do
    Leonardo.new(train_range)
  end.select do |leo|
    trained_profit = leo.profit_on_range(train_range)
    leo.initial_possibility_used = (trained_profit.first-100.0)/(trained_profit.last-100.0)
    leo.initial_possibility_used > 0.3
  end

  # puts "Trained Leos:"
  # trained_leos.each do |leo|
  #   # puts "initial_possibility_used=#{leo.initial_possibility_used}"
  #   profit = leo.profit_on_range(-100000..-1)
  #   possibilities << [(profit.first-100.0)/(profit.last-100.0), leo.initial_possibility_used]
  # end

  # puts possibilities

  size = 50

  winners = []

  INTERVALS = 30
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

  # winners.

  winners.each do |leo|
    leo.compatative_profit = leo.profit_on_range(-10000..-1).first
  end

  winners.sort_by! { |leo| leo.compatative_profit }.reverse!
  winners.each do |leo|
    p [leo.initial_possibility_used, leo.check_score, leo.compatative_profit]
  end

  winners.first.save!
end