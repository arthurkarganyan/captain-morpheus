require 'bundler'
Bundler.require(:default)

require_relative 'lib/poloniex_wrapper'
require 'active_support/all'

task :c do
  binding.pry
end

PERIODS = {'5m' => 300,
           '15m' => 900,
           '30m' => 1800,
           '2h' => 7200,
           '4h' => 14400,
           '1d' => 86400}

[:csv_to_redis, :polo_to_redis, :polo_to_csv].each do |task_name|
  task task_name do
    start_date = DateTime.parse(ENV["start_date"]).to_i
    end_date = DateTime.parse(ENV["end_date"]).to_i
    period = PERIODS[ENV["period"]] || ENV["period"].to_i
    pair = ENV["pair"] || fail("pair should be present")

    unless PERIODS.values.include?(period)
      fail("period= incorrect. Possible values: #{PERIODS.keys+PERIODS.values}")
    end

    puts "Running '#{task_name}'"

    CandlePicker.new(start_date, end_date, period, pair).send(task_name)
  end
end

class CandlePicker
  attr_reader :start_date, :end_date, :period, :pair

  def initialize(start_date, end_date, period, pair)
    @start_date = start_date
    @end_date = end_date
    @period = period
    @pair = pair
  end

  def redis
    @redis ||= Redis.new(db: 4, host: ENV["REDIS_HOST"] || "127.0.0.1")
  end

  # def pairs
  #   # From redis:
  #   #
  #   # LPUSH pairs USDT_BTC USDT_LTC USDT_ETH
  #   # pairs = redis.lrange(:pairs, 0, -1).freeze
  #   # redis.select(4)
  #   #
  #   # Hardcoded:
  #
  #   ["USDT_BTC"]
  # end

  KEYS = %w(date high low open close) # volume quoteVolume weightedAverage)

  def polo_to_redis
    unless File.exists?(csv_path)
      puts "#{csv_path} doesn't exist. Creating from Poloniex"
      polo_to_csv
    else
      puts "#{csv_path} exists"
    end

    csv_to_redis
  end

  def clear_redis!
    keys = redis.keys("#{pair}:#{period}:*")
    keys.each { |key| redis.del(key) }
  end

  def csv_to_redis
    sizes = KEYS.map { |i| redis.llen("#{pair}:#{period}:#{i}") }
    if sizes.uniq.size != 1
      puts "inconsistency!"
      clear_redis!
    end

    if sizes[0] > 0
      puts "DB is already filled. Clearing data!"
      clear_redis!
    end

    KEYS.each do |key|
      ary = []
      CSV.foreach(csv_path) do |row|
        next if row[0] == 'date'
        ary << row[KEYS.index(key)]
      end
      redis.rpush("#{pair}:#{period}:#{key}", ary)
      puts "Pushing to redis key: #{key}"
    end

    # last_date = redis.lrange("#{pair}:#{period}:date", -1, -1)[0].to_i
    # time_passed = Time.now.to_i - last_date
    # return if time_passed < period
    # start_date = (last_date == 0) ? 3.weeks.ago.to_i : last_date
    # opts = {
    #   period: period,
    #   start_date: start_date,
    #   end_date: Time.now.to_i
    # }
    # h = PoloniexWrapper.chart_data(pair, opts)
    # h.pop # last is current!
    # KEYS.each do |key|
    #   ary = []
    #   h.each do |i|
    #     ary << i[key]
    #   end
    #   redis.rpush("#{pair}:#{period}:#{key}", ary)
    # end
  end

  def opts
    {
      period: period,
      start_date: start_date,
      end_date: end_date
    }
  end

  def csv_path
    "csvs/#{pair}_#{start_date}_#{end_date}_#{period}.csv"
  end

  def polo_to_csv
    h = PoloniexWrapper.chart_data(pair, opts)
    puts "Size: #{h.size}"
    CSV.open(csv_path, "wb") do |csv|
      csv << h.first.keys
      h.each { |elem| csv << elem.values }
    end
  end
end

# 
# period: 5.minutes.to_i,
# start_date: 3.years.ago.to_i,
# end_date: Time.now.to_i
