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
-export([broadcast/1, broadcast1/1, remove/1,
  remove_and_send_token/1, test_scatter/1, test_supervisor/0]).

init_ring(N) -> PID = singletonRing:start(),
  init_ring(N - 1, PID).

init_ring(0, PID) ->
  PID;

init_ring(N, PID) -> NEWPID = node:start(),
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

init_ring1(N) -> PID = node_statem:start_link(),
  gen_statem:cast(PID, start),
  init_ring1(N - 1, PID, PID).

init_ring1(0, First, PID) ->
  {First, PID};

init_ring1(N, First, PID) -> NEWPID = node_statem:start_link(),
  %timer:sleep(1000),
  gen_statem:cast(NEWPID, {connectTo, PID}),
  init_ring1(N - 1, First, NEWPID).

waitTestTokenAcks1(0) ->
  io:fwrite("~nall test tokens received~n");

waitTestTokenAcks1(N) ->
  receive
    {testTokenAck, PID} ->
      io:fwrite("test token ackknowledgement received from ~p~n", [PID]),
      waitTestTokenAcks(N - 1)

  after 3000 -> io:fwrite("broadcast timeout~n")
  end.

broadcast(NODES) ->
  init_ring(NODES) ! {testToken, self(), self()},
  waitTestTokenAcks(NODES).

broadcast1(NODES) ->
  gen_statem:cast(element(2, init_ring1(NODES)), {testToken, self()}),
  waitTestTokenAcks(NODES).

remove(NODES) ->
  gen_statem:cast(element(2, init_ring1(NODES)), stop).

remove_and_send_token(NODES) when NODES < 2 -> ok;

remove_and_send_token(NODES) ->
  {First, Pid} = init_ring1(NODES),
  gen_statem:cast(Pid, stop),
  gen_statem:cast(First, {testToken, self()}).
  %waitTestTokenAcks(NODES - 1).

test_msg(0) -> [];

test_msg(N) ->
  [N | test_msg(N - 1)].

test_scatter(NODES) ->
  {First, Pid} = init_ring1(NODES),
  gen_statem:cast(Pid, {testScatter, test_msg(NODES / 2)}),
  gen_statem:cast(Pid, {testScatter, test_msg(NODES) / 2}).

test_supervisor() ->
  node_supervisor:start_link().

