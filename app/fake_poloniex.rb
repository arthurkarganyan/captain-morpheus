class FakePoloniex
  DEFAULT_PERIOD = 300

  def self.chart_data(pair, h)
    cd = chart_data_obj(pair, DEFAULT_PERIOD)

    dates = cd[:date]
    start_index = nil
    current_time = h[:start_date].to_i
    DEFAULT_PERIOD.times do |i|
      break if start_index = dates.index(current_time-i)
    end
    # start_index = cd[:date].index { |i| i == h[:start_date] }

    fail("h[:period] != #{DEFAULT_PERIOD}") if DEFAULT_PERIOD != h[:period]

    res = []

    i = 0
    loop do
      break if Time.now.to_i < current_time
      res << cd[:close][start_index + i]
      current_time += DEFAULT_PERIOD
      i += 1
    end

    res << sell_price_at_now(pair)
    res.map { |i| {"close" => i} }
  end

  def self.order_book(pair)
    {sells: [[sell_price_at_now(pair), 10]]}
  end

  def self.sell_price_at_now(pair)
    cd = chart_data_obj(pair, DEFAULT_PERIOD)
    dates = cd[:date]
    current_time = Time.now
    # FIXME can be optimized
    DEFAULT_PERIOD.times do |i|
      if index = dates.index((current_time-i).to_i)
        high = cd[:high][index]
        low = cd[:low][index]
        open = cd[:open][index]
        close = cd[:close][index]

        candle = Candle.new(DEFAULT_PERIOD, high, low, open, close)
        return candle.price_at(i)
      end
    end

    puts "imposibrl!"
    binding.pry
  end

  def self.redis
    @@redis ||= Redis.new(db: CONFIG[:train_redis_db])
  end

  def self.chart_data_obj(pair, period)
    @@chart_data ||= {}
    @@chart_data["#{pair}_#{period}"] ||= ChartData.new(-50000..-1, period, pair)
  end
end