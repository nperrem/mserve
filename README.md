# mserve
Enhanced mserve load balanced solution

Nathan Perrem
First Derivatives
2013-05.22

This is a heavily modified version of Arthur Whitney's mserve solution which can be found at code.kx:
https://code.kx.com/trac/wiki/Cookbook/LoadBalancing

The purpose of mserve is to provide load balancing capabilities so that queries from one or more client
can be sent to the master who will then distribute these queries to the servants in a efficient load balanced way.
The servants will then send the results back to the master who sends the results back to the client.

The main enhancements in this version are:
  Master retains details of client queries in an internal table called queries. queries table keeps track on status/location
  of all queries.
  Master sends query (FIFO) to a servant only when that servant is available.
  Dropped connections to client or servant are now handled.
  Client sends master message as a pair - (query,callback).
    where callback is the name or definition of the client's delegated callback function. This callback will handle the returned result.
  
On Windows, to kick off the master, 4 servants and 4 clients, simply run the included .bat file.
On Linux, create an appropriate .sh file from the .bat file or kick off processes in separate shells.
