class Candle
  attr_reader :high_time_point, :low_time_point, :period, :high, :low, :open, :close

  def initialize(period, high, low, open, close)
    fail unless high
    fail unless low
    fail unless open
    fail unless close
    fail unless period

    @high_time_point, @low_time_point = rand(10..(period-10)), rand(10..(period-10))
    @high_time_point -= 5 if @high_time_point == @low_time_point
    @period = period
    @high = high
    @low = low
    @open = open
    @close = close
  end

  def price_at(seconds_from_period)
    fail("should be < #{period}") if seconds_from_period >= period

    return high if seconds_from_period == high_time_point
    return low if seconds_from_period == low_time_point
    return open if seconds_from_period == 0
    return close if seconds_from_period == period - 1

    if low_time_point < high_time_point
      if (0..low_time_point).include?(seconds_from_period)
        return open - ((seconds_from_period - 0)*(open - low))/(low_time_point - 0)
      elsif (low_time_point..high_time_point).include?(seconds_from_period)
        return low + ((seconds_from_period - low_time_point)*(high - low))/(high_time_point-low_time_point)
      elsif (high_time_point..period).include?(seconds_from_period)
        return high - ((seconds_from_period - high_time_point)*(high - close))/(period - high_time_point)
      end
    else
      if (0..high_time_point).include?(seconds_from_period)
        return open + ((seconds_from_period - 0)*(high - open))/(high_time_point-0)
      elsif (high_time_point..low_time_point).include?(seconds_from_period)
        return low + ((seconds_from_period - low_time_point)*(high - low))/(high_time_point-low_time_point)
      elsif (low_time_point..period).include?(seconds_from_period)
        return low + ((seconds_from_period - low_time_point)*(close - low))/(period-low_time_point)
      end
    end

    puts "imposible!"
    binding.pry
  end
end