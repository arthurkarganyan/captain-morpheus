require 'yaml'
require 'bundler'
Bundler.require(:default)
require 'active_support/all'

require_relative 'app/captain'
require_relative 'app/candle_picker'
require_relative 'app/moose'
require_relative 'app/responder'
require_relative 'app/zhdun'
require_relative 'app/hermes'
require_relative 'app/new_hermes'
require_relative 'app/trade_machine'
require_relative 'app/candle'
require_relative 'app/fake_poloniex'

require_relative 'lib/float'
require_relative 'lib/array'
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
  ENV[key.to_s] || CONFIG.fetch(key.to_s) || fail("Key `#{key}` not found")
end

$redis = Redis.new(db: CONFIG[:telegram_redis_db])

BOT_LOGGER = Logger.new(BASE_PATH + CONFIG[:telegram_log_path])

SECRETS_HASH = CONFIG["secrets"]

AFTER_FEE = 1-0.0025
INDICATORS = [:rsi12, :trend12, :trend24, :mavg12coef, :mavg24coef]
LEARNING_RATE = 0.05
NET_ITERATIONS = 10000
HIDDEN_NODES = 3


