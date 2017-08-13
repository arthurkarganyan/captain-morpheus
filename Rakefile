require_relative 'load_config'

task :c do
  binding.pry
end

task :moose do
  range = -1200..-1
  close_prices = ChartData.new(range)[:close]
  # ideal_buys = Rockefeller.ideal_buys_and_sells(close_prices).first

  # if balance_btc > 0.0
  #   if profit(sell_price) > (last_buy_usd*0.001)
  #     logger.info(str + "Decided to sell")
  #     sell!(sell_price)
  #     notifier && notifier.notify!
  #   else
  #     logger.info(str + "Decided to sell but profit=#{profit(sell_price).round(2)}")
  #   end
  # else
  #   logger.info(str + "Decided to sell but there is no BTC")
  # end


  balance_usd = 100.0
  balance_btc = 0.0

  ary = []
  # 1000.times do |i|
  # k = 0.99+rand(0..1.0)/10.0
  k =0.985
  profit = Moose.new.profit_on_range(range, true, k).first
  ary << [k, profit]
  # end

  p ary.sort_by { |i| i.last }
end

def prof(file_name = 'prof')
  RubyProf.start
  # ActiveRecord::Base.send(:define_method, :to_s) do
  #   self.class.to_s
  # end
  res = yield
  results = RubyProf.stop
  results.eliminate_methods!([/FactoryGirl/, /ActiveRecord/, /Makara/])
  file_path = "tmp/#{file_name}-stack.html"
  File.open file_path, 'w' do |file|
    RubyProf::CallStackPrinter.new(results)
      .print(file, min_percent: 0.1, expansion: 0.1, print_file: true)
  end
  puts "written to #{file_path}"
  res
end

task :run_trade_machine do
  trade_machine = TradeMachine.new("USDT_BTC")

  $start = Time.parse('2017-02-07')
  COUNT = 20000

  class Time
    class << Time
      def new
        $start
      end

      def now
        Time.new
      end
    end
  end

  i = 0
  sell_prices = []
  rsi_ary = []
  maxx_ary = []
  minn_ary = []
  profit_points_ary = []
  stepped_out_ary = []
  sma_ary = []

  loop do
    trade_machine.run!
    sell_prices << trade_machine.sell_price
    rsi_ary << trade_machine.current_rsi
    maxx_ary << trade_machine.maxx_threshold
    minn_ary << trade_machine.minn_threshold
    profit_points_ary << trade_machine.profit_point*1.002
    sma_ary << trade_machine.current_sma
    if trade_machine.stepted_out
      stepped_out_ary << trade_machine.sell_price
    else
      stepped_out_ary << 0.0
    end

    $start += 300.seconds
    i += 1
    if i%COUNT == 0
      # fast_plot(maxx: maxx_ary, minn: minn_ary.lg, sell_prices: sell_prices.lg.map{|i| i*10.0}, rsi: rsi_ary)
      # maxx_ary =
      # Array.new(maxx_ary.size) { |i| i }
      new_maxx_ary = [[], []]
      (maxx_ary.size - 1).times do |j|
        if maxx_ary[j]
          new_maxx_ary.first << j
          new_maxx_ary.first << maxx_ary[j]
        end
      end

      fast_plot(yrange: [sell_prices.min, sell_prices.max],
                sell_prices: sell_prices,
                maxx_ary: maxx_ary,
                rsi: rsi_ary.map { |i| i+1200 },
                # rsi_lim: rsi_ary.map { |i| 35.0+1200 },
                # stepped_out_ary: stepped_out_ary,
                # sma: sma_ary,
                min: minn_ary,
                # profit_point: profit_points_ary
      )
      p [trade_machine.hermes.balance_usd, trade_machine.hermes.balance_btc, trade_machine.hermes.final_usd(sell_prices)]
      break
      sell_prices = []
      rsi_ary = []
      maxx_ary = []
      minn_ary = []
      profit_points_ary = []
    end
  end
  # binding.pry
end

task :test_trade_machine do
  $start = Time.parse('2017-03-01')

  class Time
    class << Time
      def new
        $start
      end

      def now
        Time.new
      end
    end
  end

  pair = "USDT_BTC"
  10.times { $start += 10.second; p(FakePoloniex.sell_price_at_now(pair)) }
  cc = FakePoloniex.chart_data(pair, period: 300, start_date: 1.day.ago)
  binding.pry
  # trade_machine = TradeMachine.new("USDT_BTC")
  # trade_machine.run!
end

task :test_price_at do
  open = 200.0
  high = 240.0
  low = 180.0
  close = 210.0

  period = 300

  fake_poloniex = Candle.new(period)

  ary = Array.new(period) { |i| fake_poloniex.price_at(open, high, low, close, i) }

  fast_plot(price: ary)
end


task :lead_the_way do
  c = Captain.new

  loop do
    c.lead_the_way!
    sleep 60
  end
end
