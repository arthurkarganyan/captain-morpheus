require 'pry'
require 'redis'
require 'pp'
require 'colorize'
require 'active_support/all'

task :c do
  binding.pry
end

# LPUSH pairs USDT_BTC USDT_LTC USDT_ETH

class Tester
  attr_accessor :print_allowed

  def run(rsi12_coef, mavg12_coef, mavg24_coef, trend12_coef, trend24_coef, lastdeal_coef, threshold, from = 30, to = ary[0].size-1)
    last_buy_price = 0
    usd_balance = START_USD
    btc_balance = 0.0

    from.upto(to) do |i|
      sum = rsi12_coef*ary[0][i] +
        mavg12_coef*ary[1][i] +
        mavg24_coef*ary[2][i] +
        trend12_coef*ary[3][i] +
        trend24_coef*ary[4][i] +
        lastdeal_coef*last_buy_price

      close = ary[5][i]

      if sum > threshold then
        decision = 1
      elsif sum < -threshold
        decision = -1
      else
        decision = 0
      end

      if decision == 1 && usd_balance > 0
        pp [dates[i], "buy BTC", usd_balance, close] if print_allowed
        btc_balance = usd_balance / close*(1-0.0025)
        usd_balance = 0
        last_buy_price = close
      elsif decision == -1 && btc_balance > 0
        pp [dates[i], "sell BTC", btc_balance, close] if print_allowed
        usd_balance = btc_balance * close*(1-0.0025)
        btc_balance = 0
      end
    end

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

PAIR = "USDT_BTC"
INDICATORS = %w(12rsi 12movingavg 24movingavg 12trend 24trend)

# every candle I can buy, wait or sell

PERIOD = 300 # 5 minutes
TRIES_NUMBER = 300
START_USD = 100.0

task :magnus do
  results = []

  tester = Tester.new

  step = 1.month/PERIOD

  TRIES_NUMBER.times do |iii|
    puts "[#{iii}/#{TRIES_NUMBER}]"
    rsi12_coef = r - 300
    mavg12_coef = r
    mavg24_coef = r
    trend12_coef = r
    trend24_coef = r
    lastdeal_coef = r
    threshold = r

    do_brake = false
    result = 0
    for x in (30..(tester.ary[0].size-1)).step(step)
      break if do_brake || x + step > tester.ary[0].size-1
      result = tester.run(rsi12_coef, mavg12_coef, mavg24_coef, trend12_coef, trend24_coef, lastdeal_coef, threshold, x, x+step)

      if result < 120.0
        result = 0
        do_brake = true
      end
    end

    if result > 0
      result = tester.run(rsi12_coef, mavg12_coef, mavg24_coef, trend12_coef, trend24_coef, lastdeal_coef, threshold)
      p result
      results << [result, rsi12_coef, mavg12_coef, mavg24_coef, trend12_coef, trend24_coef, lastdeal_coef, threshold]
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

  puts tester.run(*best)

  binding.pry

  # Best:
  # [7847052.289021084, -690, 275, -125, 376, -427, -47, -14],
  # [8188181.811712229, -734, 132, -180, 34, 476, 168, 256],
  # [8211632.287761635, -775, 69, -87, -477, -46, 132, -113],
  # [8277561.820051758, -634, -459, 379, 489, -465, 170, 249],
  # [8439053.144221487, -295, -310, 247, 132, -329, 105, -443],
  # [9636438.49293087, -727, 16, -67, -365, -435, 169, 24],
  # [10287258.491444938, -365, -125, 180, 197, -492, 5, -5],
  # [11125357.592085125, -709, 140, 20, 389, 98, -51, 464]]
  # per year

  # pp "Best member: #{magnus_pop.best_member.inspect}"
  # [4928.172217025622, -204, -82, 496, 458, 139, -367, -366],
  # [4928.172217025622, -380, -56, 313, 21, -344, 292, -56],
  # [4928.172217025622, -325, 343, 355, 321, 255, -208, -157],
  # [4928.172217025622, -44, 99, 18, 397, 10, -38, 303],
  # [4928.172217025622, 84, -28, 306, -267, 174, 303, -340],
  # [4958.1343856800695, -358, -142, 135, -320, 302, -254, 448],
  # [4958.1343856800695, 224, -482, -81, -362, -105, 106, 207],
  # [4958.1343856800695, -230, -245, -404, -58, 113, -476, -15]]

  # For all the time:
  # [12323904.371836694, -436, 167, -264, -7, -109, 181, 456],
  # [12495577.549982082, -546, 249, 257, -291, 442, -417, -498],
  # [21083415.01020706, -407, -98, 218, -28, 57, -42, 477],
  # [23370196.094400126, -733, -55, -43, 474, -69, 217, 93],
  # [23962941.83296464, -389, -230, 486, -485, 255, -194, -136],
  # [28668371.737726696, -697, 375, 92, -344, 254, -366, -456],
  # [29816063.118774295, -751, -106, 388, -416, -149, -147, 352],
  # [46715880.082512416, -766, -152, 338, -9, 325, -100, -385],
  # [66590770.49385245, -420, -15, -33, -463, -157, 116, 351],
  # [68527604.07897913, -491, -53, -316, -78, 361, 435, -282],
  # [270770320.35356176, -760, -290, 66, 349, -460, 324, -305],
  # [338248877.733546, -788, -479, 272, -15, -269, 309, -259],
  # [464924830.6824115, -776, -466, 375, -40, 491, 196, 18]]

  # [81.69199099754738, 43.0, 6.0, 38.0, 33.0, 17.0, 49.0]
  # [129.08288287430594, -38.0, 41.0, -47.0, 19.0, -7.0, 39.0]
  # 43.0, 6.0, 38.0, 33.0, 17.0, 49.0
  # -38.0, 41.0, -47.0, 19.0, -7.0, 39.0

  # [347.35138191817833, -379, -10, 346, 231, -261, -227, 244],
  #   [352.43118221949123, -720, -54, 477, -118, 208, -325, 425],
  #   [363.81452213261855, -580, 231, 364, 482, -362, -447, 171],
  #   [432.01033959804795, 62, 139, -381, -342, -127, 388, 479],
  #   [435.00256935043296, -150, -216, -168, 210, 73, 411, -384]]
  #

  # rsi12_coef, mavg12_coef, mavg24_coef, trend12_coef, trend24_coef, lastdeal_coef, threshold = [-709, 140, 20, 389, 98, -51, 464]
  # [190167541620.42578, -422, -121, -2, 153, 356, -71, -279]
end
