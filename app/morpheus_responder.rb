require 'singleton'

class MorpheusResponder < AbstractResponder
  include Singleton

  def auth_condition
    text == "/afs02154712hq9211r29" || chat_id == 306583100
  end

  cmd :lastbuy, ->(responder) { responder.reply(hermes.last_buy_price.try(:round, 2) || "no last buy") }
  cmd :state, ->(responder) { responder.reply(state) }
  cmd :buyprice, ->(responder) { responder.reply(DataLayer.new.buy_price.round(2)) }
  cmd :sellprice, ->(responder) { responder.reply(DataLayer.new.sell_price.round(2)) }
  cmd :changes, ->(responder) { responder.reply(Changer.new(poloniex_client_clazz, pair).changes.to_s) }
  cmd :profitpoint, ->(responder) { responder.reply(profit_point) }
  cmd :info, ->(responder) do
    responder.reply({"buy_price" => DataLayer.new.buy_price.round(2),
                     "sell_price" => DataLayer.new.sell_price.round(2),
                     "profit_point" => hermes.profit_point.try(:round, 2) || "no profit point",
                     "last_buy_price" => hermes.last_buy_price.try(:round, 2) || "no last buy"}.frmt)
  end
  cmd :balances, ->(responder) { responder.reply(Balances.new(poloniex_client_clazz).balances!.frmt) }

  def handle
    data_layer = DataLayer.new

    hermes.clear_balances!
  end

  def hermes
    @hermes = NewHermes.new(pair, poloniex_client_clazz, redis)
  end

  def trade_machine
    @trade_machine ||= nil
  end
end