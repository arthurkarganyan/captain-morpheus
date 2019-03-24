require 'pry'
require 'redis'
require 'pp'
require 'colorize'
require 'active_support/all'

# LPUSH pairs USDT_BTC USDT_LTC USDT_ETH

class Tester
  attr_accessor :print_allowed

  def run(rsi12_coef, mavg12_coef, mavg24_coef, trend12_coef, trend24_coef, lastdeal_coef, threshold, from = 30, to = ary[0].size-1)
    last_buy_price = 0
    usd_balance = START_USD
    btc_balance = 0.0
    decisions = []

    from.upto(to) do |i|
      activation_function = rsi12_coef*ary[0][i] +
        mavg12_coef*ary[1][i] +
        mavg24_coef*ary[2][i] +
        trend12_coef*ary[3][i] +
        trend24_coef*ary[4][i] +
        lastdeal_coef*last_buy_price

      close = ary[5][i]

      if activation_function > threshold then
        decision = 1 # buy
      elsif activation_function < -threshold
        decision = -1
      else
        decision = 0
      end
      #
      # decisions << decision

      if decision == 1 && usd_balance > 0
        puts [dates[i], "buy BTC", usd_balance.round(2), close.round(2)].join(", ") if print_allowed
        btc_balance = usd_balance / close*(1-0.0025)
        usd_balance = 0
        last_buy_price = close
      elsif decision == -1 && btc_balance > 0
        if print_allowed
          gain = ((1-0.0025)*btc_balance*(close - last_buy_price)).round(2)
          if gain < 0
            gain = (gain.to_s + " USD").colorize(:red)
          else
            gain = ("+" + gain.to_s + " USD").colorize(:green)
          end
          puts [dates[i], "sell BTC", btc_balance.round(2), close.round(2), gain].join(", ")
        end
        usd_balance = btc_balance * close*(1-0.0025)
        btc_balance = 0
      end
    end

    # return 0 if decisions.count { |i| i == 1} == 0
    usd_balance + btc_balance * ary.last.last
  end

  def redis
    @redis ||= Redis.new(db: 4)
  end

  def all_size
    @all_size ||= redis.llen("#{PAIR}:#{PERIOD}:close")
  end

  def ary
    return @ary if @ary
    @ary = []

    (INDICATORS + ['close']).map do |j|
      @ary << redis.lrange(construct_key(j), 0, all_size).map(&:to_f)
      puts "Loading #{j}"
    end

    @ary
  end

  def construct_key(key)
    "#{PAIR}:#{PERIOD}:#{key}"
  end

  def dates
    return @dates if @dates
    @dates = redis.lrange(construct_key("date"), 0, all_size).map { |i| Time.at(i.to_i) }
    @dates
  end
end

def r(minus = -500)
  (rand(1000)+minus)
end

def rand_ary(size, max)
  Array.new(size) { rand(max)*(rand(2) == 0 ? -1 : 1) }
end

PAIR = "USDT_BTC"
INDICATORS = %w(12rsi 12movingavg 24movingavg 12trend 24trend)

# every candle I can buy, wait or sell

PERIOD = 300 # 5 minutes
START_USD = 100.0

class Magnus
  attr_accessor :best, :calibration_max
  
  def tries_number
    @tries_number ||= (ENV['tries'] || fail("define tries=[number]")).to_i
  end

  def run
    results = []

    tester = Tester.new
    tester.dates
    tester.ary

    step = 1.month/PERIOD

    first_date = tester.dates.first.to_i
    from_date = DateTime.parse("2017-06-01").to_i
    from_count = (from_date - first_date) / PERIOD
    from_count = 30

    tries_number.times do |iii|
      puts "[#{iii}/#{tries_number}]"
      coefs = best && calibrate_best || rand_ary(7, 500)
      # rsi12_coef = r
      # mavg12_coef = r
      # mavg24_coef = r
      # trend12_coef = r
      # trend24_coef = r
      # lastdeal_coef = r
      # threshold = r

      do_brake = false
      result = 0

      for x in (from_count..(tester.ary[0].size-1)).step(step)
        break if do_brake || x + step > tester.ary[0].size-1
        result = tester.run(*coefs, x, x+step)

        if result < 90.0
          result = 0
          do_brake = true
        end
      end

      if result > 0
        result = tester.run(*coefs, from_count)
        if result > 105
          to_add = [result, *coefs]
          results << to_add
        end
      end
    end

    puts "[result, rsi12_coef, mavg12_coef, mavg24_coef, trend12_coef, trend24_coef, lastdeal_coef, threshold]"
    results = results.sort_by { |i| i.first }
    pp results
    puts ""
    puts ""
    puts "[result, rsi12_coef, mavg12_coef, mavg24_coef, trend12_coef, trend24_coef, lastdeal_coef, threshold]"

    puts "Best candidate:"
    pp results.last

    puts ""
    puts "Final result from #{START_USD} USD:"
    puts "#{results.last[0].round(2)} USD"
    puts ""

    puts "Expected profit from #{START_USD} USD:"
    puts "+#{results.last[0].round(2) - START_USD} USD"

    puts ""
    puts "Wow!"
    puts ""

    puts ""
    puts "Testing best:"
    puts ""

    tester.print_allowed= true

    best = results.last
    best.shift

    puts tester.run(*best, from_count)
  end

  def calibrate_best
    best.map { |i| i + rand(calibration_max)*(rand(2) == 0 ? -1 : 1) }
  end
end

task :magnus do
  Magnus.new.run
end

task :c do
  binding.pry
end

task :test_best do
  tester = Tester.new
  tester.print_allowed = true
  puts tester.run(*[-467, -433, 424, -406, -313, 69, 351])
end

task :calibrate_best do
  magnus = Magnus.new
  magnus.best = [-467, -433, 424, -406, -313, 69, 351]
  magnus.calibration_max = 50
  magnus.run
end

