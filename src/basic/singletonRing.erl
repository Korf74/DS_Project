%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Apr 2017 16:04
%%%-------------------------------------------------------------------
-module(singletonRing).
-author("remi").

%% API
-export([start/0, work/0]).

start() ->
  spawn(?MODULE, work, []).

addingNode(PID) ->
  PID ! {become, self(), pairRing, start, [self()]},
  receive
    {connected, PID} -> pairRing:start(PID)
  end.

work() ->
  %io:fwrite("self : ~p -> singleton ring~n", [self()]),
  receive
    {addNode, PID} -> addingNode(PID);

    {testToken, FROM, INIT} ->
      INIT ! {testTokenAck, self()},
      io:fwrite("~p received the test token from ~p~n", [self(), FROM])
  end.