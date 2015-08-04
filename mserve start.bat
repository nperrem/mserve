start "Start Master Process on 6000" q mserve_np.q -p 6000 4 servant.q
start "Start Client 1" q client.q -sym IBM -master 6000
start "Start Client 2" q client.q -sym UBS -master 6000
start "Start Client 3" q client.q -sym GS -master 6000
start "Start Client 4" q client.q -sym AAPL -master 6000
