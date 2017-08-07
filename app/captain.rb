class Captain

  def period
    300
  end

  def clear_redis!
    redis.keys("#{pair}:#{period}:*").each { |key| redis.del(key) }
  end

  def refresh_data!
    clear_redis!
    fill_close_prices!
    fill_indexes!
  end

  def pair
    "USDT_BTC"
  end

  def fill_close_prices!
    orders = Poloniex::Client.order_book(pair)
    candles = Poloniex::Client.chart_data(pair, period: period, start_date: (Time.now-60*60*2).to_i)
    close = candles.map { |i| i["close"] }
    close.pop
    close << orders[:sells].first.first
    $captain_redis.rpush("#{pair}:#{period}:close", close)
  end

  def fill_indexes!
    folder = `pwd`.chomp.split('/')[0..-2].join("/") + '/indexer'
    res = `INDEXER_REDIS_DB=#{CAPTAIN_REDIS_DB} ~/.virtualenvs/indexer/bin/python #{folder}/main.py`
    fail("Something went wrong with indexer!") unless res.chomp == 'Done!'
  end

end