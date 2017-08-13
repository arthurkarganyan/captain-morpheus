class MainLoop
  PAIRS = ["USDT_LTC"]
  SLEEP_TIME = 5

  def run
    Telegram::Bot::Client.run(CONFIG[:bot_token], logger: BOT_LOGGER, timeout: 3) do |bot|
      bot.logger.info('Bot has been started')
      bot.fetch_updates do |msg|
        bot.logger.info("Clearing messages from last session: #{msg}")
      end

      # Responder.all(bot).each(&:remove_kb!)
      loop do
        bot.fetch_updates { |msg| Responder.find_or_create(bot, msg).handle! }
        Responder.all(bot).each do |i|
          msg = Responder.telegram_redis.rpop("msgs_to_send:#{i.chat_id}")
          i.reply(msg) if msg
        end

        trade_machines.each(&:run!)

        if @telegram_options.nil? || @telegram_options != trade_machines.flat_map(&:telegram_options)
          @telegram_options = trade_machines.flat_map(&:telegram_options)
          Responder.current.add_kb(@telegram_options) if @telegram_options.size > 0
        end

        sleep SLEEP_TIME
      end
    end
  end

  def trade_machines
    @trade_machines ||= PAIRS.map { |i| TradeMachine.new(i) }
  end
end
