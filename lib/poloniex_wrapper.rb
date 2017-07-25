class PoloniexWrapper
	Poloniex.setup do |config|
	  	config.key = ENV["POLONIEX_KEY"] || fail("POLONIEX_KEY variable not defined")
	    config.secret = ENV["POLONIEX_SECRET"] || fail("POLONIEX_SECRET variable not defined")
	end

	def self.method_missing(sym, *args)
		puts "#{sym}, #{args}"
		res = try_send(sym, *args)
		JSON.parse(res)
	end

	def self.try_send(sym, *args)
		Poloniex.public_send(sym, *args)
	end
end