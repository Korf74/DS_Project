%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Apr 2017 16:04
%%%-------------------------------------------------------------------
-module(genRing).
-author("remi").

%% API
-export([work/4, start/4]).

start(NNEXT, NEXT, PREV, PPREV) ->
  monitor(process, NNEXT),
  monitor(process, NEXT),
  monitor(process, PREV),
  monitor(process, PPREV),
  work(NNEXT, NEXT, PREV, PPREV).

addingNode(NNEXT, NEXT, PREV, PPREV, PID) ->
  receive
    {connected, PID} -> work(NNEXT, NEXT, PREV, PPREV)
  end.

work(NNEXT, NEXT, PREV, PPREV) ->
  %io:fwrite("self : ~p -> node in gen ring ~p ~p ~p ~p~n", [self(), NNEXT, NEXT, PREV, PPREV]),
  receive
    % Node addition
    {addNode, PID} -> % pprev
      NEXT ! {addingNode, PID, [self()]},
      addingNode(PID, NEXT, PREV, PPREV, PID);

    {addingNode, PID, POLLED} ->
      case length(POLLED) of
        3 -> % nnext --  cheat on convention + not really clean
          PID ! {become, self(), genRing, work, [self() | POLLED]},
          addingNode(NNEXT, NEXT, PREV, PID, PID);

        2 -> % next
          NEXT ! {addingNode, PID, [self() | POLLED]},
          addingNode(NNEXT, NEXT, PID, PREV, PID);

        1 -> % prev
          NEXT ! {addingNode, PID, [self() | POLLED]},
          addingNode(NEXT, PID, PREV, PPREV, PID);

        _ -> io:fwrite("error when adding to genRing~n")
      end;

    % tests
    {testToken, FROM, INIT} ->
      io:fwrite("~p received the test token from ~p~n", [self(), FROM]),
      NEXT ! {testToken, self(), INIT},
      INIT ! {testTokenAck, self()}
  end.
