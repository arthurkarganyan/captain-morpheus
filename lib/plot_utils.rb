def fast_plot(hash)
  Gnuplot.open do |gp|
    Gnuplot::Plot.new(gp) do |plot|
      plot.data = hash.map do |key, value|
        value = {data: value} unless value.is_a? Hash

        Gnuplot::DataSet.new(value.delete(:data)) do |ds|
          ds.title = key
          ds.with = value[:with] || "lines"
        end
      end
    end
  end
end

def data_set(data, title, with)
  Gnuplot::DataSet.new(data) do |ds|
    ds.with = with.to_s
    ds.title = title.to_s
  end
end

def data_plot(ary)
  Gnuplot.open do |gp|
    Gnuplot::Plot.new(gp) do |plot|
      plot.data = ary.map { |i| data_set(i.first, i[1], i[2]) }
    end
  end
end
