class Responder
  attr_reader :bot, :msg, :chat_id

  def initialize(bot, msg)
    @bot = bot
    self.msg = msg
  end

  def auth?
    !!@auth
  end

  def handle!
    bot.logger.info("[Responder#handle!] chat_id=#{msg.chat.id}: #{text}")
    return try_auth unless auth?
    $redis.rpush("received_msgs:#{msg.chat.id}", text)
    reply "I am alive!" if text == "/ping"
  end

  def try_auth
    SECRETS_HASH.each do |k, v|
      if "/" + k == text
        @auth = true
        reply "You are authorized, #{v}!"
        return
      end
    end
  end

  def msg=(msg)
    @msg = msg
    @chat_id = msg.chat.id
  end

  def text
    msg.text
  end

  def reply(text)
    bot.logger.info("Replying: #{text}")
    bot.api.send_message(chat_id: msg.chat.id, text: text)
  end

  def self.find_or_create(bot, msg)
    responder = all.detect { |i| i.chat_id == msg.chat.id }
    if responder
      responder.msg = msg
      return responder
    end
    responder = Responder.new(bot, msg)
    unless $redis.lrange(:active_responders, 0, -1).include?(msg.chat.id.to_s)
      $redis.rpush(:active_responders, msg.chat.id)
    end
    $responders << responder
    responder
  end

  def self.all
    $responders ||= []
  end
end