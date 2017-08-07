require 'yaml'
require "redis"

path = File.expand_path(File.dirname(__FILE__)) + '/'
CONFIG = YAML.load_file(path + 'config.yml')
CAPTAIN_REDIS_DB = CONFIG['captain_redis_db']

$redis = Redis.new(db: CONFIG['telegram_redis_db'] || fail)
$captain_redis = Redis.new(db: CAPTAIN_REDIS_DB || fail)

BOT_LOGGER = Logger.new(path + CONFIG['telegram_log_path'])
CAPTAIN_LOGGER = Logger.new(path + CONFIG['captain_log_path'])
SECRETS_HASH = CONFIG["secrets"]
