class Hermes
  attr_reader :logger, :sell_price, :notifier
  attr_accessor :balance_usd, :balance_btc, :last_buy_usd, :profit_sum, :last_buy_price

  def initialize(logger, balance_usd, balance_btc, notifier = nil, current_range)
    @logger = logger
    @balance_usd = balance_usd
    @balance_btc = balance_btc
    @notifier = notifier
    @profit_sum = 0.0
    @missed_buys = 0
    @last_buy_price = 0.0
    @current_range = current_range
  end

  # my_data = Indicators::Data.new chart_data.map {|i| i["close"]}
  # rsi_indexes = my_data.calc(type: :rsi, params: 28).output

  def new_handle!
    yield
  end

  RSI = 30

  def handle!(sell_price, buy_signal, sell_signal, current_iteration)
    cc=ChartData.new(@current_range)[:close]
    rsi = Indicators::Data.new(cc).calc(type: :rsi, params: 12).output.map { |i| i && i.round(1) }

    # @last_sell_prices << sell_price
    # my_data = Indicators::Data.new @last_sell_prices

    @shit = true if last_buy_price && last_buy_price / sell_price > 1.05

    last_buy_color = @shit ? :red : :blue

    rsi_color = if (rsi[current_iteration] || 0.0) < 30.0
                  :red
                elsif rsi[current_iteration] > 70.0
                  :green
                else
                  :yellow
                end

    str = ""
    str << "#{rsi[current_iteration] && ("%0.1f" % rsi[current_iteration]).colorize(rsi_color)} | "
    str << "#{("%0.1f" % last_buy_price).colorize(last_buy_color)} | "
    str << "#{"%0.1f" % (sell_price*AFTER_FEE)} | "
    str << "#{"%0.1f" % (sell_price/AFTER_FEE)} | "
    str << "buy=#{buy_signal.round(1)} | "
    str << "sell=#{sell_signal.round(1)} | "


    if buy_signal > 0.9
      @missed_buys += 1
      if balance_usd > 0.0 &&
        if rsi[current_iteration] && rsi[current_iteration] < 30.0 && rsi[current_iteration-1] && rsi[current_iteration-1] < rsi[current_iteration]
          logger.info(str + "Decided to buy")
          buy!(sell_price)
          notifier && notifier.notify!
          @missed_buys = 0
        else
          logger.info(str + "Decided to buy but RSI=#{rsi[current_iteration]}")
        end
      else
        logger.info(str + "Decided to buy but there is no USD")
      end
    elsif sell_signal > 0.9
      # puts "fun" if balance_btc > 0.0 && profit(sell_price) < 0
      if balance_btc > 0.0
        if profit(sell_price) > (last_buy_usd*0.001)
          logger.info(str + "Decided to sell")
          sell!(sell_price)
          notifier && notifier.notify!
        else
          logger.info(str + "Decided to sell but profit=#{profit(sell_price).round(2)}")
        end
      else
        logger.info(str + "Decided to sell but there is no BTC")
      end
    else
      logger.info(str + "Decided to hold")
    end

    # rescue
    #   binding.pry
  end

  def profit(sell_price)
    return 0 unless last_buy_usd
    AFTER_FEE*(balance_btc * sell_price) - last_buy_usd
  end

  def buy!(sell_price)
    return unless balance_usd > 0
    self.last_buy_usd = balance_usd
    self.last_buy_price = sell_price/AFTER_FEE
    self.balance_btc = AFTER_FEE*(balance_usd / sell_price)
    logger.info("Buy:  got #{"%0.5f" % balance_btc} for #{sell_price/AFTER_FEE} | -#{"%0.1f" % balance_usd} USD")
    self.balance_usd = 0.0
  end

  def sell!(sell_price)
    return unless balance_btc > 0
    # fail("Stop-trade") if profit(sell_price) < 0.0 && balance_usd*0.001 < -profit(sell_price)
    self.balance_usd = AFTER_FEE*(balance_btc * sell_price)
    self.profit_sum += profit(sell_price)
    logger.info("Sell: got #{"%0.1f" % balance_usd} USD for #{"%0.1f" % (sell_price*AFTER_FEE)} | -#{"%0.5f" % balance_btc} BTC | Profit=#{profit(sell_price).round(1).traffic_light(0.0)} | Sum=#{profit_sum.round(1).traffic_light(0.0)}")
    self.balance_btc = 0.0
    self.last_buy_usd = 0.0
    self.last_buy_price = 0.0
  end

  def final_usd(close_prices)
    if balance_usd == 0.0
      (balance_btc / AFTER_FEE) * close_prices.last
    else
      balance_usd
    end
  end

  def a
    last_buy_usd = 0.0
    sum_profit = 0.0

    locker = nil

    (close_prices.size-1).times do |i|
      # if locker && (locker.first > close_prices[i] || locker.last < close_prices[i])
      #   locker = nil
      # end

      # p [buys[i], sells[i]]
      if buys[i] > 0.7 && sells[i] < (0.3) && balance_usd > 0.0
        last_buy_usd = balance_usd
        balance_btc = (balance_usd * AFTER_FEE) / close_prices[i]
        balance_usd = 0.0
        locker = [close_prices[i]*AFTER_FEE, close_prices[i]/AFTER_FEE]
        puts "#{i}, buy=#{(close_prices[i]/AFTER_FEE).round(1)} #{balance_usd.round(2)}, #{balance_btc.round(5)}"
      elsif buys[i] < 0.3 && sells[i] > 0.7 && balance_btc > 0.0 && locker && (locker.first > close_prices[i] || locker.last < close_prices[i])
        balance_usd = (balance_btc / AFTER_FEE) * close_prices[i]
        profit = balance_usd - last_buy_usd
        sum_profit += profit
        balance_btc = 0.0

        profit = profit.round(1)
        profit = profit > 0 ? profit.to_s.colorize(:green) : profit.to_s.colorize(:red)
        puts "#{i}, sell=#{(close_prices[i]*AFTER_FEE).round(1)}, #{balance_usd.round(2)}, #{balance_btc.round(5)}, profit=#{profit}"
      end
    end
  end
end