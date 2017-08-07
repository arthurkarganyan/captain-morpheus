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
