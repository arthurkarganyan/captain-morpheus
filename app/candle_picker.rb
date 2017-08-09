class CandlePicker
  attr_reader :start_date, :end_date, :period, :pair

  def initialize(start_date, end_date, period, pair)
    if start_date.is_a? String
      @start_date = DateTime.parse(start_date).to_i
    else
      @start_date = start_date
    end
    if end_date.is_a? String
      @end_date = DateTime.parse(end_date).to_i
    else
      @end_date = end_date
    end
    @period = period
    @pair = pair
  end

  def redis
    @redis ||= Redis.new(db: redis_db, host: ENV["REDIS_HOST"] || "127.0.0.1")
  end

  def redis_db
    ENV["CANDLE_PICKER_REDIS_DB"] || fail("CANDLE_PICKER_REDIS_DB variable is not set")
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

  def transform_values(v)
    v[0] = Time.at(v[0].to_i).strftime("%Y-%m-%d")
    1.upto(4) do |i|
      v[i] = Math.log(v[i])
    end
    v
  end

  def polo_to_csv
    h = Poloniex::Client.chart_data(pair, opts)
    puts "Size: #{h.size}"
    CSV.open(csv_path, "wb") do |csv|
      csv << h.first.keys
      # h.size.times do |i|
      #
      # end
      to_add = []
      h.each do |elem|
        to_add << transform_values(elem.values)
        #
        # csv << v
      end

      # 0 date
      # 1 high
      # 2 low
      # 3 open
      # 4 close
      # to_add_new = []
      # last = nil

      high, low, open, close = to_add[0][1], to_add[0][2], to_add[0][3], to_add[0][4]
      last_date = to_add[0]
      green = to_add[0][4] > to_add[0][3]

      1.upto(to_add.size) do |i|
        if to_add.size == i || (green != (to_add[i][4] > to_add[i][3]))
          csv << [last_date, high, low, open, close]
          if to_add[i]
            last_date, high, low, open, close = to_add[i][0], to_add[i][1], to_add[i][2], to_add[i][3], to_add[i][4]
            green = to_add[i][4] > to_add[i][3]
          end
        else
          high = [to_add[i][1], high].max
          low = [to_add[i][2], low].min
          open = [to_add[i][3], open].send(green ? :min : :max)
          close = [to_add[i][4], close].send(green ? :max : :min)
          last_date = to_add[i][0]
        end
      end
    end
  end
end
