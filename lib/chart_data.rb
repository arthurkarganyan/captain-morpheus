PAIR = "USDT_BTC"

PERIOD = 300 # 5 minutes
START_USD = 100.0


class ChartData
  attr_reader :range

  def initialize(range)
    @range = range

    secs = size*PERIOD
    hours = secs/3600.0
    days = secs/(24*3600.0)
    months = secs/(30*24*3600.0)
    puts("Created chart with duration: ")
    puts("#{months.round(1)} months") if months > 1
    puts("#{days.round(1)} days") if days > 1
    puts("#{hours.round(1)} hours") if hours > 1
  end

  def size
    range.size
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

    time = Benchmark.measure do
      (INDICATORS + ['close']).map do |j|
        @ary << redis.lrange(construct_key(j), 0, all_size).map(&:to_f)
        puts "Loading #{j}"
      end
    end.real
    puts "Took #{time} sec"

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

  def [](key)
    specific(key)
  end

  def specific(*key_or_keys)
    if key_or_keys.size == 1
      key = key_or_keys.first.to_sym
      return @specific[key] if @specific && @specific[key]
      @specific ||= {}
      time = Benchmark.measure do
        @specific[key] = redis.lrange(construct_key(key), range.first, range.last).map(&:to_f)
      end.real
      puts "Loaded #{key} for #{time} sec"
      @specific[key]
    else
      key_or_keys.map do |key|
        specific(key)
      end
    end
  end
end