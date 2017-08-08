class Array
  def sum
    inject(0.0) { |result, el| result + el }
  end

  def mean
    sum / size
  end

  def avg
    mean
  end

  def median
    sorted = self.sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end
end
