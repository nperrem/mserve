/
This client will connect to the master process and send a query
sample usage:q client.q -sym IBM -master 5000

\

args:.Q.opt[.z.x];
args[`sym]:first`$args[`sym];
args[`master]:first"J"$args[`master];

/res will be a list containing all the result sets
results:([qid:`int$()]
			query:();
			result:()
	); 

/client query signature:
/h(request;callback_function)
/client callback signature:
/callback[qid;query;result]
/example client side callback function:
callback1:{[qid;query;result]
							show (qid;query;result);
							`results upsert (qid;query;result);
							};

h:neg hopen args[`master];

/h("proc1";args[`sym])

/example client query:
h(("proc1";args[`sym]);"callback1")
/h@("proc1[`IBM]";"callback1")

.z.ts:{h(("proc1";rand `GS`AAPL`BA`VOD`MSFT`GOOG`IBM`UBS);"callback1")
	};
	
/\t 500	
