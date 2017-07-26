require 'bundler'
Bundler.require(:default)
require 'active_support/all'

require_relative 'lib/poloniex_wrapper'

require_relative 'app/model/message_formatter'
require_relative 'app/model/responder'
require_relative 'app/model/pair_info'
require_relative 'app/model/candle'
require_relative 'app/model/new_pair_info'
require_relative 'app/view/pair_presenter'
require_relative 'app/poloniex_assistant'
require_relative 'app/notification/mail_service'
require_relative 'app/model/poloniex_data_provider'


MAKER_FEE = 0.0015
TAKER_FEE = 0.0025

# $p = PoloniexDataProvider.new(PoloniexWrapper)
# puts $p.chart_data_for("USDT_LTC")

# PoloniexWrapper.cha

