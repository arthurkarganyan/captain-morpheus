class Responder
  attr_reader :bot, :msg, :chat_id, :telegram_redis

  attr_writer :chat_id, :auth

  def initialize(telegram_redis, bot, msg = nil)
    @bot = bot
    @telegram_redis = telegram_redis
    if msg
      self.msg = msg
    end
  end

  def auth?
    !!@auth
  end

  def handle!
    bot.logger.info("[Responder#handle!] chat_id=#{chat_id}: #{text}")
    return try_auth unless auth?
    telegram_redis.rpush("received_msgs:#{chat_id}", text)
    reply "I am alive!" if text == "/ping"
  end

  def try_auth
    SECRETS_HASH.each do |k, v|
      if "/" + k == text
        @auth = true
        reply "You are authorized, #{v}!"
        unless telegram_redis.lrange(:authorized_responders, 0, -1).include?(chat_id.to_s)
          telegram_redis.rpush(:authorized_responders, chat_id)
        end
        return
      end
    end
  end

  def msg=(msg)
    @msg = msg
    @chat_id = (msg.try(:chat) || msg.from).id
  end

  def text
    msg.try(:text) || msg.try(:data)
  end

  def reply(text, markup = nil)
    bot.logger.info("Replying: #{text} #{markup if markup}")

    opts = {chat_id: chat_id, text: text}
    opts[:reply_markup] = markup if markup
    bot.api.send_message(opts)
  end

  def add_kb(answers)
    # markup =  Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: answers, one_time_keyboard: true)
    buttons = answers.map do |i|
      Telegram::Bot::Types::InlineKeyboardButton.new(text: i, callback_data: i)
    end
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [buttons])
    reply("Adding KB", markup)
  end

  def remove_kb!
    markup = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
    reply("Removing KB", markup)
  end

  # def remove_kb_markup
  #   Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
  # end

  def with_keyboard(answers)
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: answers, one_time_keyboard: true)
  end

  def self.find_or_create(bot, msg)
    responder = all(bot).detect do |i|
      i.chat_id.to_s == (msg.try(:chat) || msg.from).id.to_s
    end
    if responder
      responder.msg = msg
      return responder
    end
    responder = Responder.new(telegram_redis, bot, msg)
    unless telegram_redis.lrange(:active_responders, 0, -1).include?(msg.chat.id.to_s)
      telegram_redis.rpush(:active_responders, msg.chat.id)
    end
    $responders << responder
    responder
  end

  def self.all(bot = nil)
    $responders ||= telegram_redis.lrange(:authorized_responders, 0, -1).map do |chat_id|
      r = Responder.new(telegram_redis, bot)
      telegram_redis.del("received_msgs:#{chat_id}")
      r.auth = true
      r.chat_id = chat_id
      r
    end
  end

  def self.telegram_redis
    @@telegram_redis ||= Redis.new(db: CONFIG[:telegram_redis_db])
  end

  def self.current
    all.first
  end
end