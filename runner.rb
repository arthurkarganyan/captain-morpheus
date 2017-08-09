require_relative 'load_config'

require 'telegram/bot'

Telegram::Bot::Client.run(config["bot_token"], logger: BOT_LOGGER, timeout: 3) do |bot|
  bot.logger.info('Bot has been started')
  loop do
    bot.fetch_updates { |msg| Responder.find_or_create(bot, msg).handle! }
    Responder.all.each do |i|
      msg = $redis.rpop("msgs_to_send:#{i.chat_id}")
      i.reply(msg) if msg
    end
  end
end

