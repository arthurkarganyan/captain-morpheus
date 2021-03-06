import index_funcs
import redis
import numpy as np
import stockstats as stst
import pandas as pd
import os

# r = redis.StrictRedis(db=2)
# pairs = r.lrange("pairs", 0, -1)
r = redis.StrictRedis(db=int(os.environ['INDEXER_REDIS_DB']))
period = 300
avg_period = 12

pair = "USDT_BTC"
# pair = pair.decode("utf-8")
close_list_key = pair + ":" + str(period) + ":close"
base_key = pair + ":" + str(period) + ":"

if r.llen(close_list_key) != 0:
    close_list = r.lrange(close_list_key, 0, -1)
    # close_list.pop(0)
    close_list = list(map(lambda x: float(x.decode("utf-8")), close_list))
    np_close_list = np.array(close_list)
    stock = stst.StockDataFrame.retype(pd.DataFrame(data=np_close_list, columns=["close"]))
    # print(list(stock['kdjj']))
    # DataFrame(data=np_close_list)
    rsi = list(map(lambda x: float(x) / 100.0, stock['rsi_' + str(avg_period)]))

    r.rpush(base_key + "rsi" + str(avg_period), *(list(rsi)))
    for avg_period in [12, 24]:
        list_key = base_key + "movingavg" + str(avg_period)
        moving_avg = (index_funcs.movingaverage(close_list, avg_period))
        r.rpush(list_key, *(close_list[:(avg_period - 1)]))
        r.rpush(list_key, *(moving_avg.tolist()))

        tmp = np.concatenate((close_list[:(avg_period)], moving_avg[:-1]))
        trend = list(np.append([0], np.diff(tmp)))
        list_key = base_key + "trend" + str(avg_period)
        r.rpush(list_key, *(trend))

    # for change in [1, 7, 30]:
    #    list_key = pair + ":" + str(period) + ":" + str(change) +"change"
    #    moving_avg=(index_funcs.movingaverage(close_list, avg_period))
    #    r.rpush(list_key, *(close_list[:(avg_period-1)]))
    #    r.rpush(list_key, *(moving_avg.tolist()))

    # [(Old Price - New Price)/Old Price]
    print("Done!")
else:
    print("No data found in the redis.")
