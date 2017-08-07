module Rockefeller
  def self.ideal_deals(new_ary)
    ideal_deals = [new_ary.first]
    1.upto(new_ary.size-1) do |i|
      sell1 = new_ary[i-1].last*AFTER_FEE
      sell2 = new_ary[i].last*AFTER_FEE
      buy1 = new_ary[i-1].last/AFTER_FEE
      buy2 = new_ary[i].last/AFTER_FEE
      unless sell1 > sell2 && sell1 < buy2 || sell1 < sell2 && buy1 > sell2
        ideal_deals << new_ary[i]
      end
    end

    new_ideal_deals = [ideal_deals.first]
    # return [] if new_ideal_deals.size < 2

    1.upto(ideal_deals.size-2) do |i|
      unless ideal_deals[i-1].last < ideal_deals[i].last && ideal_deals[i].last < ideal_deals[i+1].last ||
        ideal_deals[i-1].last > ideal_deals[i].last && ideal_deals[i].last > ideal_deals[i+1].last

        new_ideal_deals << ideal_deals[i]
      end
    end

    new_ideal_deals << ideal_deals.last

    if new_ary.size == new_ideal_deals.size
      new_ideal_deals.pop if new_ideal_deals[-1].last < new_ideal_deals[-2].last
      new_ideal_deals.shift if new_ideal_deals[1].last < new_ideal_deals[0].last
      return new_ideal_deals
    end

    ideal_deals(new_ideal_deals)
  end

  def self.local_extremum(close_prices)
    local_extremum = []

    1.upto(close_prices.size - 1) do |i|
      if close_prices[i-1] > close_prices[i] && close_prices[i+1] && close_prices[i+1] >= close_prices[i] ||
        close_prices[i-1] < close_prices[i] && close_prices[i+1] && close_prices[i+1] <= close_prices[i]

        local_extremum << [i, close_prices[i]]
      end
    end
    local_extremum
  end

  def self.ideal_buys_and_sells(chart_data_close)
    ideal_deals = ideal_deals(local_extremum(chart_data_close))
    ideal_buys = [[], []]
    ideal_sells = [[], []]
    ideal_deals.size.times do |i|
      if i % 2 == 0
        ideal_buys.first << ideal_deals[i].first
        ideal_buys.last << ideal_deals[i].last
      else
        ideal_sells.first << ideal_deals[i].first
        ideal_sells.last << ideal_deals[i].last
      end
    end
    [ideal_buys, ideal_sells]
  end
end