require 'yaml'
require "redis"

BASE_PATH = File.expand_path(File.dirname(__FILE__)) + '/'

CONFIG = YAML.load_file(BASE_PATH + 'config.yml')

def CONFIG.[](key)
  CONFIG.fetch(key.to_s) || fail("Key `#{key}` not found")
end

$redis = Redis.new(db: CONFIG[:telegram_redis_db])
$captain_redis = Redis.new(db: CONFIG[:captain_redis_db])

BOT_LOGGER = Logger.new(BASE_PATH + CONFIG[:telegram_log_path])
CAPTAIN_LOGGER = Logger.new(BASE_PATH + CONFIG[:captain_log_path])

SECRETS_HASH = CONFIG["secrets"]

INDICATORS = %w(rsi12 trend12 trend24)
AFTER_FEE = 1-0.0025
