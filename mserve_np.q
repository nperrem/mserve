/ 
Nathan Perrem
First Derivatives
2013-05.22

This is a heavily modified version of Arthur Whitney's mserve solution which can be found at code.kx:
https://code.kx.com/trac/wiki/Cookbook/LoadBalancing

The purpose of mserve is to provide load balancing capabilities so that queries from one or more clients
can be sent to the master who will send these queries in a load balanced way to the servants.
The servants will then send the results back to the master who sends the results back to the client

Sample usage:  q mserve_np.q -p 5001 2 servant.q

.z.x 0 - 1st argument - number of servant to start up
.z.x 1 - 2nd argument - the script we want each servant to load 

On startup of the master process, the following steps take place:
1. Master decides on the port numbers the servants will listen on
2. Master starts up the servant processes listening on the required ports 
3. Master connects to the servants
4. Master sends a message to each servant telling servant to:
	a)define .z.pc such that servant terminates when master disconnects
	b)load in the appropriate script so the servant has data

We maintain a dictionary on the master process which keeps track on all the outstanding requests on the servants.
This dictionary maps each servant handle to a list of all query ids for whom that servant has requests currently.

All the communication between client-master, master-servant, servant-master and master-client is asynchronous.

1 Store query as well as client handle when new request is received by master
2 assign unique id to each new query
3 Store combination of client handle,query id,query and call back function in queries table
4 Do not automatically send new query to least busy servant, instead only send new query when a servant is free

\

\c 10 150

/list of the port numbers the servants will listen on
p:(value"\\p")+1+til"J"$.z.x 0

/Start up the multiple servant processes
{system"q -p ",(string x)}each p


/ unix (comment out for windows)
/\sleep 1

/ connect to servants. h is a list of asynch handles
h:neg hopen each p;
/servant will terminate if disconnected from master
h@\:".z.pc:{exit 0}";
/servant loads in script
h@\:"\\l ",.z.x[1];

/map each servant asynch handle to an empty list and assign resultant dictionary back to h
/The values in this dictionary will be the unique query ids currently outstanding on that servant (should be max of one)
h!:()
 
.z.pg:{:"SEND MESSAGE ASYNCH!"};

queries:([qid:`u#`int$()]
		query:();
		client_handle:`int$();
		client_callback_function:();
		time_received:`time$();
		time_returned:`time$();
		slave_handle:`int$();
		location:`symbol$()
		);

/update `u#qid from `queries;		

send_query:{[hdl]
	qid:exec first qid from queries where location=`master;
	/if there is an outstanding query to be sent, try to send it
	if[not null qid;
	query:queries[qid;`query];
	h[hdl],:qid;
	queries[qid;`slave_handle]:hdl;
	queries[qid;`location]:`slave;
	hdl({[qid;query](neg .z.w)(qid;@[value;query;`error])};qid;query)
	];
 };

send_result:{[qid;result]
	query:queries[qid;`query];
	client_handle:queries[qid;`client_handle];
	client_callback_function:queries[qid;`client_callback_function];
	client_handle(client_callback_function;qid;query;result);
	/break[];
	queries[qid;`location`time_returned]:(`client;.z.T);
	 }; 
 
/check if free slave. If free slave exists -> try to send oldest query 
check:{[]
	if[not 0N=hdl:?[count each h;0];send_query[hdl]];
 }; 
 
/
.z.ps is where all the action resides. As said already, all communication is asynch, so any request from a client
or response from a servant will result in .z.ps executing on the master

input to .z.ps is x
There are 2 possibilities
1. x is a query received from a client
2. x is a result received from a servant

.z.w stores the asynch handle back to whoever has sent the master the asynch message (either a client or servant)

We have an if else statement checking whether the call back handle (.z.w) to the other process exists in the key of h or not
if .z.w exists in h => message is a response from a servant
if .z.w does not exist in h => message is a new request from a client
\ 
.z.ps:{[x]
	$[not(w:neg .z.w)in key h;
	/request
	[
	/x@0 - request
	/x@1 - callback_function
	new_qid:1^1+exec last qid from queries; /assign id to new query
	`queries upsert (new_qid;first x;(neg .z.w);last x;.z.T;0Nt;0N;`master);
	/check for a free slave.If one exists,send oldest query to that slave
	check[];
	];
	/response
	[
	/x@0 - query id
	/x@1 - result
	qid:first x;
	result:last x;
	/try to send result back to client
	.[send_result;
		(qid;result);
		{[qid;error]queries[qid;`location`time_returned]:(`client_failure;.z.T)}[qid]
	 ];
	/drop the first query id from the slave list in dict h
	h[w]:1_h[w];
	/send oldest unsent query to slave
	send_query[w];
	]];	
 };
 
/Change location of queries outstanding on the dead servant to master
.z.pc:{
	update location:`master from `queries where qid in h@neg x; /reassign lost queries to master process (for subsequent re-assignment)
	h::h _ (neg x); /remove dead servant handle from h
	check[];
	/if client handle went down, remove outstanding queries
	delete from `queries where location=`master,client_handle=neg x;
 };
