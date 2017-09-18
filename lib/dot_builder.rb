class DotBuilder
  PATH = 'tmp/trade_machine.dot'

  class << self
    def run
      open(PATH, 'w') { |f| f.puts text }
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
end