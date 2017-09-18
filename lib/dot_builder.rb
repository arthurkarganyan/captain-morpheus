class DotBuilder
  PATH = 'tmp/trade_machine.dot'

  class << self
    def run
      open(PATH, 'w') do |f|
        f.puts text
      end
      %x(xdot #{PATH})
    end

    def transitions_text
      res = ""
      TradeMachine::TRANSITIONS.each do |state, transitions|
        transitions.each do |method, to_state|
          res << "\"#{state}\" -> \"#{to_state}\"[label=\"#{method}\"]\n"
        end
      end
      res
    end

    def colors_text
      TradeMachine::STATES.map do |i|
        color = TradeMachine::COLORS[i]
        "\"#{i}\" [shape=box, color=#{color}];\n"
      end.join
    end

    def text
      res = "digraph {\n"
      res << transitions_text
      res << colors_text
      res << "}\n"
      res
    end
  end

  # digraph {
  #     "going_up" -> "buy_lock"[label="sell!"]
  #     "buy_lock" -> "going_down" [label="unlock!"]
  #     "going_down" -> "profit_waiting"  [label="auto_buy!"]
  #     "going_down" -> "profit_waiting"  [label="manual_buy!"]
  #     "profit_waiting" -> "going_up" [label="reached_profit_point!"]
  #
  #     "going_up" [shape=box, color=green];
  #     "going_down" [shape=box, color=red];
  #     "buy_lock" [shape=box, color=blue];
  #     "profit_waiting" [shape=box, color=purple];
  # }
end