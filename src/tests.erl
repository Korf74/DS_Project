%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Apr 2017 21:12
%%%-------------------------------------------------------------------
-module(tests).
-author("remi").

%% API
-export([broadcast/1]).

init_ring(N) -> PID = spawn(singletonRing, work, []),
  init_ring(N - 1, PID).

init_ring(0, PID) ->
  PID;

init_ring(N, PID) -> NEWPID = spawn(node, idle, []),
  %timer:sleep(1000),
  NEWPID ! {connectTo, PID},
  init_ring(N - 1, NEWPID).

waitTestTokenAcks(0) ->
  io:fwrite("~nall test tokens received~n");

waitTestTokenAcks(N) ->
  receive
    {testTokenAck, PID} ->
      io:fwrite("test token ackknowledgement received from ~p~n", [PID]),
      waitTestTokenAcks(N - 1)

    after 3000 -> io:fwrite("broadcast timeout~n")
  end.

broadcast(NODES) ->
  init_ring(NODES) ! {testToken, self(), self()},
  waitTestTokenAcks(NODES).