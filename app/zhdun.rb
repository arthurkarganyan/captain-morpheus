class Zhdun # http://gordonua.com/img/article/1726/66_tn.jpg
  # error minimizer algorithm
  # already waited
  #
  # min
  # optimum wait range should be calculated = all buys
  #
  # optimum = avg(distance_between(any_buy, first_profitable_sell(min_profit = 0.1))
  attr_reader :range, :profit, :min_profit

  MIN_PROFIT = 0.004

  def initialize(range, min_profit)
    @range = range
    @profit = []
    @min_profit = min_profit
  end

  def chart_data
    $chart_data ||= ChartData.new(range)
  end

  def close_prices
    @close_prices ||= chart_data[:close]
  end

  def distances
    res = []
    (close_prices.size-1).times do |i|
      first_profitable = first_profitable_sell(i)
      if first_profitable
        res << first_profitable - i
      else
        res << nil
      end
      # puts res.last
    end
    res
  end

  def distances_chart
    fast_plot(dist: normalized_distances.sort)
  end

  def normalized_distances
    @normalized_distances ||= distances.map { |i| i.nil? ? range.size : i }.sort
  end

  def first_profitable_sell(buy_index)
    (buy_index+1).upto(close_prices.size-1) do |i|
      # return nil if i - buy_index > close_prices.size/2
      buy_price = close_prices[buy_index]/AFTER_FEE
      sell_price = close_prices[i]*AFTER_FEE
      if buy_price < sell_price/(1+min_profit)
        @profit << (sell_price / buy_price)-1
        return i
      end
    end

    nil
  end

  def profit
    return @profit
    Math.log(@profit)
  end

  def koef
    # koef(n) =
  end
end