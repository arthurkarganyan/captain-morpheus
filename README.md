# README #

The orders manager!

![Morpheus](http://screencrush.com/files/2017/03/Mootrix-Moopheus.jpg?w=360)

### Redis DB description ###

| DB no.  | Description 	|
| ------- | ------------- |
| 1  	  | Is used by Telegram Sparrow Bot  |
| 4  	  | Is used for testing algorithms by candle-picker, indexer, magnus\leonardo |
| 5  	  | Is used for production by candle-picker, indexer, leonardo |
| 6  	  | Is used by leonardo to store trained network |

### Enviroment Setup ###

1. Make sure you have [RVM](https://rvm.io/) installed. Check installation via `rvm -v`.
2. Add `[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"` to `.bashrc` or `.zshrc`.
3. [Redis](https://redis.io/) should be installed also. `sudo apt-get update && sudo apt-get install redis-server`
4. Python should be installed.

### For Ruby Projects ###

1. Goto project folder
2. Make sure that correct gemset is loaded: `rvm current` should produce something like `ruby-2.3.0@[project-name]`
3. `gem install bundle`
4. `bundle`

### For Python Projects ###

TODO: pip install, virtualenv?

### Architecture ###

TODO: general info

### Making system work! ###

Redis should work.
Api key & Secret from Poloniex should be added to `.bashrc`:
```
export POLONIEX_KEY="..."
export POLONIEX_SECRET="..."
```
Setup `https://bitbucket.org/generation-p/candle-picker`

Run it with e.g. `pair=USDT_BTC period=5m start_date=2016-01-01 end_date=2017-01-01 rake polo_to_redis`

Make sure that data is added to redis. Goto `redis-cli`:

```
> select 4
> keys *
#
# Expected output:
# 127.0.0.1:6379[4]> keys *
# 1) "USDT_BTC:300:close"
# 2) "USDT_BTC:300:high"
# 3) "USDT_BTC:300:open"
# 4) "USDT_BTC:300:low"
# 5) "USDT_BTC:300:date"
#
```

Setup `https://bitbucket.org/generation-p/indexer`

Run it via `python main.py`

Make sure that new data is added to redis. Goto `redis-cli`:

```
> select 4
127.0.0.1:6379[4]> keys *
# Expected output:

# 1) "USDT_BTC:300:high"
# 2) "USDT_BTC:300:low"
# 3) "USDT_BTC:300:12trend"
# 4) "USDT_BTC:300:24movingavg"
# 5) "USDT_BTC:300:close"
# 6) "USDT_BTC:300:24trend"
# 7) "USDT_BTC:300:open"
# 8) "USDT_BTC:300:12movingavg"
# 9) "USDT_BTC:300:12rsi"
# 10) "USDT_BTC:300:date"
```

Now we are ready to make some algorithm expirements! :)

Run: `rake magnus`
