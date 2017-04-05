%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Apr 2017 16:04
%%%-------------------------------------------------------------------
-module(pairRing).
-author("remi").

%% API
-export([work/1]).

addingNode(PEER, PID) ->
  PID ! {become, self(), tripleRing, work, [PEER, self()]},
  receive
    {connected, PID} ->
      PEER ! {become, self(), tripleRing, work, [self(), PID]},
      tripleRing:work(PID, PEER)
  end.

idle(PEER) ->
  receive
    {become, PEER, MODULE, FUN, ARGS} -> apply(MODULE, FUN, ARGS);

    unpause -> work(PEER)
  end.

work(PEER) ->
  %io:fwrite("self : ~p -> node paired with ~p~n", [self(), PEER]),
  receive
    pause -> idle(PEER);

    {addNode, PID} ->
      PEER ! pause,
      addingNode(PEER, PID);

    {testToken, FROM, INIT} ->
      io:fwrite("~p received the test token from ~p~n", [self(), FROM]),
      PEER ! {testToken, self(), INIT},
      INIT ! {testTokenAck, self()}
  end.