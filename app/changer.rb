class Changer
  attr_reader :pair, :poloniex_client_clazz

  SEGMENTS = [1.day, 3.days, 1.week, 1.month]

  def initialize(poloniex_client_clazz, pair)
    @poloniex_client_clazz = poloniex_client_clazz
    @pair = pair
  end

  def changes
    res = {}
    SEGMENTS.map do |segment|
      key = "#{segment.parts.first.last}#{segment.parts.first.first.to_s[0]}" # 1.day => "1d"
      res[key] = change_for(segment)
      sleep 2
    end
    @current_price = nil
    res
  end

  PERIOD = 300

  def change_for(segment)
    chart_data = poloniex_client_clazz.chart_data(pair, period: PERIOD,
                                                  start_date: segment.ago.to_i,
                                                  end_date: (segment.ago+PERIOD+1).to_i).first

    (current_price/chart_data["close"] - 1).round(2)
  end

  def current_price
    @current_price ||= poloniex_client_clazz.ticker[pair]["last"].to_f
  end
end