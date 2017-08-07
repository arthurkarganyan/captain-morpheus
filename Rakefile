require_relative 'load_config'

task :c do
  binding.pry
end

task :lead_the_way do
  c = Captain.new

  loop do
    c.lead_the_way!
    sleep 60
  end
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

task :train_leo do
  train_range = -3000..-2950

  trained_leos = Array.new(2) do
    Leonardo.new(train_range)
  end.select do |leo|
    trained_profit = leo.profit_on_range(train_range)
    leo.initial_possibility_used = (trained_profit.first-100.0)/(trained_profit.last-100.0)
    leo.initial_possibility_used > 0.3
  end

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

  winners.each do |leo|
    leo.compatative_profit = leo.profit_on_range(-10000..-1).first
  end

  winners.sort_by! { |leo| leo.compatative_profit }.reverse!
  winners.each do |leo|
    p [leo.initial_possibility_used, leo.check_score, leo.compatative_profit]
  end

  winners.first.save!
end
