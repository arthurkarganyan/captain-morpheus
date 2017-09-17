class MainLoop
  LANGUAGES = [:en, :fr, :es]
  SLEEP_TIME = 5

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
    return cmds['/help'].call unless cmds[last_msg]

    logger.info("Received cmd: #{last_msg}")
    l = cmds[last_msg]
    l.call
  end

  def run
    Telegram::Bot::Client.run(CONFIG[:bot_token], logger: BOT_LOGGER, timeout: 3) do |bot|
      bot.logger.info('Bot has been started')

      loop do
        bot.fetch_updates { |msg| Responder.find_or_create(bot, msg).handle! }

        # if @telegram_options.nil? || @telegram_options != trade_machines.flat_map(&:telegram_options)
        #   @telegram_options = trade_machines.flat_map(&:telegram_options)
        #   Responder.current.add_kb(@telegram_options) if @telegram_options.size > 0
        # end

        sleep SLEEP_TIME
      end
    end
  end
end
