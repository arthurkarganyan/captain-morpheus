class Hash
  def frmt
    str = ""

    self.each do |k, v|
      str << "#{k}: #{v}\n"
    end

    str
  end
end