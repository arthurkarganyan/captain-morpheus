class Balances
  attr_reader :poloniex_clazz

  def initialize(poloniex_clazz)
    @poloniex_clazz = poloniex_clazz
  end

  def balances!
    sleep 1
    Hash[poloniex_clazz.available_account_balances["exchange"].map do |k, v|
      [k, v.to_f*0.999]
    end]
  end
end