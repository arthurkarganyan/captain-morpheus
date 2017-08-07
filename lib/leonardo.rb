class Leonardo # Da Vinci
  include Competitor

  attr_reader :train_range, :ideal_buys, :ideal_sells
  attr_accessor :initial_possibility_used, :compatative_profit, :check_score, :buy_net, :sell_net

  def initialize(train_range = nil)
    @train_range = train_range

    @ideal_buys, @ideal_sells = Rockefeller.ideal_buys_and_sells(chart_data[:close]) if train_range
  end

  def vector_for_index(i)
    normalize_indicators(*[rsi12_ary[i], trend12_ary[i], trend24_ary[i]])
  end

  def buy_inputs
    buy_inputs = []

    fail("fuck!") if [rsi12_ary.size, trend12_ary.size, trend24_ary.size].uniq.size != 1

    train_range.size.times do |i|
      if ideal_buys.first.include?(i)
        buy_inputs << [vector_for_index(i), 1]
        buy_inputs << [vector_for_index(i), 1]
        buy_inputs << [vector_for_index(i), 1]
      elsif ideal_sells.first.include?(i)
        buy_inputs << [vector_for_index(i), 0]
        buy_inputs << [vector_for_index(i), 0]
      end
    end

    # buy_inputs << [vector_for_index(25), 0]

    (ideal_buys.first.size * 2).times do
      i = rand(train_range.size)
      unless ideal_buys.first.include?(i)
        buy_inputs << [vector_for_index(i), 0]
      end
    end

    buy_inputs
  end

  def sell_inputs
    sell_inputs = []

    train_range.size.times do |i|
      if ideal_sells.first.include?(i)
        sell_inputs << [vector_for_index(i), 1]
        sell_inputs << [vector_for_index(i), 1]
        sell_inputs << [vector_for_index(i), 1]
      elsif ideal_buys.first.include?(i)
        sell_inputs << [vector_for_index(i), 0]
        sell_inputs << [vector_for_index(i), 0]
      end
    end

    # local_mins = []
    #
    # local_extremum.size.times do |i|
    #   local_mins << local_extremum[i] if i % 2 == 0
    # end

    # local_mins.size.times do |i|
    #   sell_inputs <<[vector_for_index(local_mins[i].first), 0]
    # end

    (ideal_sells.first.size * 2).times do
      i = rand(train_range.size)
      unless ideal_sells.first.include?(i)
        sell_inputs << [vector_for_index(i), 0]
      end
    end

    sell_inputs
  end

  ITERATIONS = 15000

  def buy_net
    return @buy_net if @buy_net

    net_trainer = NetTrainer.new(buy_inputs)
    net_trainer.num_hidden_nodes = 5
    net_trainer.iterations = ITERATIONS
    net_trainer.learning_rate = 0.05

    @buy_net ||= net_trainer.generate
  end

  def sell_net
    return @sell_net if @sell_net

    net_trainer = NetTrainer.new(sell_inputs)
    net_trainer.num_hidden_nodes = 6
    net_trainer.iterations = ITERATIONS
    net_trainer.learning_rate = 0.05

    @sell_net ||= net_trainer.generate
  end

  def chart_data
    @chart_data ||= ChartData.new(train_range)
  end

  def rsi12_ary
    @rsi12_ary ||= chart_data[:rsi12]
  end

  def trend12_ary
    @trend12_ary ||= chart_data[:trend12]
  end

  def trend24_ary
    @trend24_ary ||= chart_data[:trend24]
  end

  def normalize_indicators(rsi12, trend12, trend24)
    [rsi12,
     sigmoid(trend12),
     sigmoid(trend24)]
  end

  def generate_buys(range)
    chart_data = ChartData.new(range)

    test_input = []

    (range.size - 1).times do |i|
      test_input << normalize_indicators(*([:rsi12, :trend12, :trend24].map { |j| chart_data[j][i] }))
    end

    output_buy = []

    test_input.each do |pattern|
      output_buy << NetTrainer.forward_propagate(buy_net, pattern).round
    end

    output_buy
  end

  def generate_sells(range)
    chart_data = ChartData.new(range)

    test_input = []

    # FIXME CHART DATA IS NOT UNIOFORM WITH VECTORO_FOR_INDEX
    (range.size - 1).times do |i|
      test_input << normalize_indicators(*([:rsi12, :trend12, :trend24].map { |j| chart_data[j][i] }))
    end

    output_sell = []

    test_input.each do |pattern|
      output_sell << NetTrainer.forward_propagate(sell_net, pattern).round
    end
    output_sell
  end

  def save!
    nets = [buy_net, sell_net]

    File.open("winners/#{compatative_profit.round}.leonardo.dump", 'w') do |f|
      f.write(Marshal.dump(nets))
    end
  end

  def self.load_from_file(path)
    m = Marshal.load(File.read(path))

    obj = self.new
    obj.buy_net = m.first
    obj.sell_net = m.last
    obj
  end

  # def buys_and_sells
  #   test_input = []
  #
  #   close_prices = ChartData.new(train_range)[:close]
  #
  #   train_range.size.upto(rsi12_ary.size-1) do |i|
  #     test_input << [rsi12_ary[i], trend12_ary[i], trend24_ary[i]]
  #   end
  #
  #   output_sell = []
  #   output_buy = []
  #
  #   test_input.each do |pattern|
  #     output_sell << forward_propagate(sell_net, pattern).round
  #     output_buy << forward_propagate(buy_net, pattern).round
  #   end
  # end

  # Zigzag
  # zigzag = []
  # ideal_deals.size.times do |i|
  #   if i % 2 == 0
  #     zigzag << ideal_deals[i]/AFTER_FEE
  #   else
  #     zigzag << ideal_deals[i]*AFTER_FEE
  #   end
  # end
  #
  # fast_plot(zigzag: zigzag,
  #           close: ideal_deals,
  #           new_possible_buys: ideal_deals.map { |i| i/AFTER_FEE },
  #           new_possible_sells: ideal_deals.map { |i| i*AFTER_FEE })

  # fail if p_ary.size != maxs.first.size + mins.first.size
  # fail if p_ary.size%2!=0
  #
  # real = Benchmark.measure do
  #   puts "Max profit:"
  #   # puts usd_at(p_ary).round(4)
  #   puts "+" + ((usd_at(zigzag)-1.0)*100.0).round(2).to_s + " %"
  # end.real
  # puts "usd_at took #{real} sec"
  # puts "Maxs:"
  # p maxs
  # puts "Mins:"
  # p mins

end