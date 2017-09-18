class Morpheus
  def self.logger
    @@logger ||= begin
      path = BASE_PATH + CONFIG[:captain_log_path] + '.' + pair + ".#{mode}"
      puts "Log written to #{path}"
      res = Logger.new(path)

      def res.info(msg)
        puts msg
        super
      end

      res
    end
  end

  def self.redis
    @@redis ||= begin
      Redis.new(db: CONFIG[:captain_redis_db])
    end
  end

  def self.poloniex_client_clazz
    if mode.to_sym == :production
      Poloniex::Client
    else
      FakePoloniex
    end
  end

  def self.mode
    CONFIG[:mode].to_sym
  end
end