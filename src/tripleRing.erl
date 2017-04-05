%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Apr 2017 16:04
%%%-------------------------------------------------------------------
-module(tripleRing).
-author("remi").

%% API
-export([work/2]).

addingNode(NEXT, PREV, PID) ->
  PID ! {become, self(), genRing, work, [PREV, NEXT, self(), PREV]},
  receive
    {connected, PID} ->
      NEXT ! {become, self(), genRing, work, [self(), PREV, PID, self()]},
      PREV ! {become, self(), genRing, work, [PID, self(), NEXT, PID]},
      genRing:work(NEXT, PID, PREV, NEXT)
  end.

idle(NEXT, PREV) ->
  receive
    {become, NEXT, MODULE, FUN, ARGS} -> apply(MODULE, FUN, ARGS);
    {become, PREV, MODULE, FUN, ARGS} -> apply(MODULE, FUN, ARGS);

    unpause -> work(NEXT, PREV)
  end.

work(NEXT, PREV) ->
  %io:fwrite("self : ~p -> node in triplet with ~p and ~p~n", [self(), NEXT, PREV]),
  receive
    pause -> idle(NEXT, PREV);

    {addNode, PID} ->
      NEXT ! pause,
      PREV ! pause,
      addingNode(NEXT, PREV, PID);

    {testToken, FROM, INIT} ->
      io:fwrite("~p received the test token from ~p~n", [self(), FROM]),
      NEXT ! {testToken, self(), INIT},
      INIT ! {testTokenAck, self()}
  end.