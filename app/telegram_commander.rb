class TelegramCommander

  def handle(last_msg)

  end

  def handle_telegram
    cmds = {
      '/debug' => lambda { binding.pry },
      '/lastbuy' => lambda { telegram_msg(hermes.last_buy_price.try(:round, 2) || "no last buy") },
      '/state' => lambda { telegram_msg(state) },
      '/buyprice' => lambda { telegram_msg(buy_price.round(2)) },
      '/sellprice' => lambda { telegram_msg(sell_price.round(2)) },
      '/changes' => lambda { telegram_msg(Changer.new(poloniex_client_clazz, pair).changes.to_s) },
      '/profitpoint' => lambda { telegram_msg(profit_point) },
      '/info' => lambda do
        telegram_msg({"buy_price" => buy_price.round(2),
                      "sell_price" => sell_price.round(2),
                      "profit_point" => profit_point.try(:round, 2) || "no profit point",
                      "last_buy_price" => hermes.last_buy_price.try(:round, 2) || "no last buy"}.frmt)
      end,
      '/balances' => lambda { telegram_msg(Balances.new(poloniex_client_clazz).balances!.frmt) },
      '/help' => lambda do
        buttons = cmds.keys.each_slice(3).map do |i|
          i.map { |j| Telegram::Bot::Types::InlineKeyboardButton.new(text: j, callback_data: j) }
        end
        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
        Responder.current.reply("Commands:", markup)
      end
    }
    return unless last_msg
    unless cmds[last_msg]
      l = cmds['/help']
      drop_last_msg
      l.call
      return
    end

    logger.info("Received cmd: #{last_msg}")
    l = cmds[last_msg]
    drop_last_msg
    l.call
  end
end