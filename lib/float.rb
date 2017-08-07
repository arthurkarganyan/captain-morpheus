class Float
  def pc
    (self * 100).round(2).to_s + '%'
  end
end