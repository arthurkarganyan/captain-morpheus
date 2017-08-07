require 'yaml'
require "redis"

path = File.expand_path(File.dirname(__FILE__)) + '/'
config = YAML.load_file(path + 'config.yml')
CAPTAIN_REDIS_DB = config['captain_redis_db']

$redis = Redis.new(db: config['telegram_redis_db'] || fail)
$captain_redis = Redis.new(db: CAPTAIN_REDIS_DB || fail)

BOT_LOGGER = Logger.new(path + config['telegram_log_path'])
CAPTAIN_LOGGER = Logger.new(path + config['captain_log_path'])
SECRETS_HASH = config["secrets"]
