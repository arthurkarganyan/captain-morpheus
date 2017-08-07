class Magnus # Carlsen
  attr_reader :input_ary, :tries

  def initialize(input_ary, tries)
    @input_ary = input_ary

    input_ary.each do |i|
      if i.max > 1.0 || i.min < -1.0
        i.map! { |j| j.to_sigmoid }
      end
    end

    validate_input(input_ary)
    @close_ary ||= $chart_data[:close]
    @tries = tries
  end

  def validate_input(input_ary)
    input_ary.each do |i|
      i.each do |j|
        if j > 1.0 || j < -1.0
          puts("Value #{j} not it range [-1; 1]")
          puts("For dataset[min=#{i.min}, max=#{i.max}]")
          fail
        end
      end
    end
  end

  def rand_coefs
    @rand_coefs ||= Array.new(tries) { Array.new(input_ary.size) { rand(-1.0..1.0) } }
  end

  # def rand_threshold
  #   @rand_threshold ||= Array.new(tries) { input_ary.size * rand(-1.0..1.0) }
  # end

  def rand_minus_threshold
    @rand_minus_threshold ||= rand_plus_threshold.map { |i| i - rand(-1.0..1.0) }
  end

  def rand_plus_threshold
    @rand_plus_threshold ||= Array.new(tries) { rand(-1.0..1.0) }
  end

  # def rand_backpropagation
  #   @rand_backpropagation ||= Array.new(tries) { input_ary.size * rand(-1.0..1.0) }
  # end

  def run(no_of_trial, result_decisions = false)
    # puts "[#{no_of_trial}/#{tries}]" if no_of_trial % 10 == 0
    usd_balance = 100.0
    btc_balance = 0.0
    last_buy_price = 0.0
    minus_threshold = rand_minus_threshold[no_of_trial]
    plus_threshold = rand_plus_threshold[no_of_trial]
    no_of_coefs = input_ary.size
    current_coefs = rand_coefs[no_of_trial]
    decisions_ary = []

    $chart_data.size.times do |i|
      close = @close_ary[i]
      sum = 0
      no_of_coefs.times { |j| sum += current_coefs[j]*@input_ary[j][i] }
      sum

    #   if sum > plus_threshold && usd_balance > 0
    #     decision = 1 # buy
    #   elsif sum < minus_threshold && btc_balance > 0
    #     decision = -1
    #   else
    #     decision = 0
    #   end
    #
    #   if decision == 1
    #     if result_decisions
    #       puts [i, "buy BTC", usd_balance.round(2), close.round(2)].join(", ")
    #     end
    #     btc_balance = (usd_balance / close) * (1-0.0025)
    #     usd_balance = 0
    #     last_buy_price = close
    #   elsif decision == -1 && btc_balance > 0
    #     if result_decisions
    #       gain = ((1-0.0025)*btc_balance*(close - last_buy_price)).round(2)
    #       if gain < 0
    #         gain = (gain.to_s + " USD").colorize(:red)
    #       else
    #         gain = ("+" + gain.to_s + " USD").colorize(:green)
    #       end
    #       puts [i, "sell BTC", btc_balance.round(2), close.round(2), gain].join(", ")
    #     end
    #     usd_balance = (btc_balance * close) * (1-0.0025)
    #     btc_balance = 0
    #     last_buy_price = 0
    #   end
    #   decisions_ary << [decision, sum] if result_decisions
    end

    if result_decisions
      decisions_ary
    else
      usd_balance + btc_balance * @close_ary.last
    end
  end

  def find_best!(top = tries)
    results = []
    res = nil
    time = Benchmark.measure do
      tries.times do |i|
        results << [run(i), i]
      end
      res = results.sort_by! { |i| i.first }.last(top)
    end.real

    puts "Calculated #{tries} tries for #{time.round(1)} sec. Speed: #{(tries/time).round(2)} try/sec"
    res
  end

end