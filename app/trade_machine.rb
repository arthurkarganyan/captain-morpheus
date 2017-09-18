class TradeMachine
  INITIAL_STATE = :buy_lock

  TRANSITIONS = {
    going_up: {sell!: :buy_lock},
    buy_lock: {unlock!: :going_down,
               manual_buy!: :profit_waiting},
    going_down: {buy!: :profit_waiting,
                 manual_buy!: :profit_waiting},
    profit_waiting: {reached_profit_point!: :going_up}
  }

  STATES = TRANSITIONS.keys

  attr_reader :state, :hermes, :pair, :stepted_out

  STATES.each do |state|
    define_method(state) do
      state == @state
    end
  end

  def initialize(pair)
    @pair = pair
    @state = load_state
    @maxx = @minn = nil

    a = "[#{self.class}:#{pair}]"
    Morpheus.logger.info("#{a} created with state: #{state_color(@state)}")
  end

  def transit(to_state, action)
    to_state, action = to_state.to_sym, action.to_sym
    fail("Unknown state #{to_state}") unless STATES.include?(to_state)
    transition_found = false
    TRANSITIONS[state].each do |k, v|
      if v == to_state && k == action
        transition_found = true
        break
      end
    end

    unless transition_found
      fail("Transition not found: #{state} -> #{to_state} by method '#{action}'")
    end

    fail("'#{action}' not implemented") unless respond_to?(action, true)

    send(action)
    logger.info("Changed state from #{state_color(state)} -> #{state_color(to_state)}")
    telegram_msg("#{pair}: Changed state from #{state} -> #{to_state}")
    @state = to_state
    redis.set(redis_state_key, to_state) if mode == :production
  end

  def redis_state_key
    "trade_machine:#{pair}:state"
  end

  def load_state
    (redis.get(redis_state_key) || INITIAL_STATE).to_sym
  end

  def telegram_msg(msg)
    MorpheusResponder.instance.reply(msg)
  end

  def handle
    send("handle_#{state}")

    TRANSITIONS[state].each do |k, v|
      return transit(v, k) if send("check_#{k.to_s.sub('!', '?')}")
    end
  end

  def minn_threshold
    @minn && @minn / CONFIG[:minn_thresh_koef]
  end

  def state_color(state)
    h={going_up: :green,
       buy_lock: :blue,
       going_down: :red,
       profit_waiting: :magenta}

    state.to_s.colorize(h[state])
  end

  def current_sma
    sma = Indicators::Data.new(chart_data_closes).calc(type: :sma, params: 48).output
    sma.last
  end

  def period
    300 #* 12 * 2
  end

  def thresh_koef
    CONFIG[:thresh_koef]
  end
end
