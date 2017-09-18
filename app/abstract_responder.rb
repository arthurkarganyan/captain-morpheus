class AbstractResponder
  attr_reader :msg, :bot

  def self.cmd(name, lambda_block)
    @@cmds ||= {}
    @@cmds["/#{name}"] = lambda_block
  end

  cmd :help, ->(responder) do
    buttons = @@cmds.keys.each_slice(3).map do |i|
      i.map { |j| Telegram::Bot::Types::InlineKeyboardButton.new(text: j, callback_data: j) }
    end
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
    responder.reply("Commands:", markup)
  end

  cmd :debug, ->(responder) { binding.pry }
  cmd :afs02154712hq9211r29, ->(responder) { responder.reply("You are authorized!") }

  def logger
    @logger ||= Morpheus.logger
  end

  def auth?
    !!@auth
  end

  def try_auth
    @auth = true if auth_condition
  end

  def run
    Telegram::Bot::Client.run(BOT_TOKEN, logger: logger, timeout: 1.5) do |bot|
      @bot ||= bot

      bot.logger.info('Bot has been started')

      loop do
        bot.fetch_updates do |msg|
          @msg = msg
          before_handle
        end
        sleep SLEEP_TIME
      end
    end
  end

  def text
    return nil unless msg
    if msg.class == Telegram::Bot::Types::CallbackQuery
      msg.data
    else
      msg.text
    end
  end

  def chat_id
    return nil unless msg
    if msg.class == Telegram::Bot::Types::CallbackQuery
      msg.from
    else
      msg && msg.chat
    end.id
  end

  def reply(text, markup = nil)
    bot.logger.info("Replying: #{text} #{markup if markup}")

    opts = {chat_id: chat_id, text: text}
    opts[:reply_markup] = markup if markup
    bot.api.send_message(opts)
  end

  def before_handle
    return unless text
    try_auth
    return unless auth?

    if text[0] == '/'
      logger.info("Received cmd: #{text}")
      splitted = text.split(":").first
      cmd = cmds[splitted] ? cmds[splitted] : cmds['/help']
      return cmd.call(self)
    end

    handle
  end

  def cmds
    @@cmds
  end
end