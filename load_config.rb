require 'yaml'
require 'bundler'
Bundler.require(:default)
require 'active_support/all'

require_relative 'lib/float'
require_relative 'app/captain'
require_relative 'app/responder'
require_relative 'lib/chart_data'
require_relative 'lib/competitor'
require_relative 'lib/magnus'
require_relative 'lib/leonardo'
require_relative 'lib/rockefeller'
require_relative 'lib/net_trainer'
require_relative 'lib/plot_utils'

BASE_PATH = File.expand_path(File.dirname(__FILE__)) + '/'

CONFIG = YAML.load_file(BASE_PATH + 'config.yml')

def CONFIG.[](key)
  CONFIG.fetch(key.to_s) || fail("Key `#{key}` not found")
end

$redis = Redis.new(db: CONFIG[:telegram_redis_db])

BOT_LOGGER = Logger.new(BASE_PATH + CONFIG[:telegram_log_path])

SECRETS_HASH = CONFIG["secrets"]

INDICATORS = %w(rsi12 trend12 trend24)
AFTER_FEE = 1-0.0025
