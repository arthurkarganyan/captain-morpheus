class Float
  def pc_traffic_light(green_limit, yellow_limit)
     correctness_color = if self >= green_limit
                          :green
                        elsif self >= yellow_limit
                          :yellow
                        else
                          :red
                        end

    res = (self * 100).round(2).to_s + '%'
    res.colorize(correctness_color)
  end

  def pc
   ("%0.2f" % (self * 100)) + '%'
  end

  def traffic_light(green_limit, yellow_limit = nil)
    correctness_color = if self >= green_limit
                          :green
                        elsif yellow_limit && self >= yellow_limit
                          :yellow
                        else
                          :red
                        end

    self.to_s.colorize(correctness_color)
  end

  def to_sigmoid
    1/(1+2.718281828459045**(-self))
  end
end