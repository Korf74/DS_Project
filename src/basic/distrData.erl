%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Mar 2017 10:36
%%%-------------------------------------------------------------------
-module(distrData).
-author("remi").

%% API
-export([work/5, init_ring/1, init_ring/2, singleton/1, singletonConnecting/6, test/1]).

init_ring(N) -> PID = spawn(distrData, work, [N, null, null, null, null]),
  init_ring(N - 1, PID).

init_ring(0, PID) -> PID;

init_ring(N, PID) -> NEWPID = spawn(distrData, singleton, [N]),
  %timer:sleep(1000),
  NEWPID ! {connect, PID},
  PID ! {addNode, NEWPID},
  init_ring(N - 1, NEWPID).

test(N) -> init_ring(N) ! test.

singleton(NUMBER) ->
  receive
    {connect, PID} -> singletonConnecting(NUMBER, self(), self(), self(), self(), [])
  end.

singletonConnecting(NUMBER, NEXT, PREV, NNEXT, PPREV, RCVDPIDS) ->
  case length(RCVDPIDS) of
    4 -> lists:foreach(fun(X) -> X ! {connected, self()} end, RCVDPIDS),
      work(NUMBER, NEXT, PREV, NNEXT, PPREV);
    _ ->
      receive
        % specific cases
        {connectOk, next, prev, PID, PID} -> PID ! {connected, self()},
          work(NUMBER, PID, PID, NNEXT, PPREV);

        % general case
        {connectOk, next, PID} -> singletonConnecting(NUMBER, NEXT, PID, NNEXT, PPREV, [PID | RCVDPIDS]);
        {connectOk, prev, PID} -> singletonConnecting(NUMBER, PID, PREV, NNEXT, PPREV, [PID | RCVDPIDS]);
        {connectOk, nnext, PID} -> singletonConnecting(NUMBER, NEXT, PREV, NNEXT, PID, [PID | RCVDPIDS]);
        {connectOk, pprev, PID} -> singletonConnecting(NUMBER, NEXT, PREV, PID, PPREV, [PID | RCVDPIDS])
      end
    end.

addingNode(NUMBER, NEXT, PREV, NNEXT, PPREV, PID) ->
  receive
    % case n = 2
    {addNode, PID, next} -> PID ! {connectOk, next, self()},
      NEXT ! {addNode, PID, prev},
      addingNode(NUMBER, PID, PREV, NEXT, PPREV, PID);

    {addNode, PID, prev} -> PID ! {connectOk, prev, self()},
      NEXT ! {addNode, PID, pprev},
      addingNode(NUMBER, NEXT, PID, NNEXT, PREV, PID);

    % case n = 3
    {addNode, PID, pprev} -> PID ! {connectOk, pprev, self()},
      addingNode(NUMBER, NEXT, PREV, NNEXT, PID, PID);

    % general case
    {connected, PID} -> work(NUMBER, NEXT, PREV, NNEXT, PPREV)
  end.


work(NUMBER, null, null, null, null) -> work(NUMBER, self(), self(), self(), self());

work(NUMBER, NEXT, PREV, NNEXT, PPREV) ->
  io:fwrite("self : ~p (~p) -> ~p, ~p, ~p, ~p~n", [NUMBER, self(), NEXT, PREV, NNEXT, PPREV]),
  %timer:sleep(1000),
  SELF = self(),
  receive
    % case n = 2
    {addNode2, PID} -> PID ! {connectOk, prev, SELF},
      PID ! {connectOk, nnext, SELF},
      addingNode(NUMBER, NEXT, PID, PID, NEXT, PID);


    %% Adding node
    {addNode, PID} -> io:fwrite("~p received addNode ~p~n", [NUMBER, PID]), case {NEXT, NNEXT} of
                        %% case n = 1
                        {SELF, SELF} -> PID ! {connectOk, next, prev, SELF, SELF},
                          addingNode(NUMBER, PID, PID, SELF, SELF, PID);
                        %% case n = 2
                        {_, SELF} -> NEXT ! {addNode2, PID},
                          PID ! {connectOk, next, SELF},
                          PID ! {connectOk, pprev, SELF},
                          addingNode(NUMBER, PID, PREV, PREV, PID, PID);

                        %% general case
                        _ -> PID ! {connectOk, nnext, SELF},
                          NEXT ! {addNode, PID, next},
                          addingNode(NUMBER, NEXT, PREV, PID, PPREV, PID)
                      end;

    {addNode, PID, next} -> io:fwrite("~p received addNode next  ~p~n", [NUMBER, PID]),PID ! {connectOk, next, self()},
      NEXT ! {addNode, PID, prev},
      addingNode(NUMBER, PID, PREV, NEXT, PPREV, PID);

    {addNode, PID, prev} -> io:fwrite("~p received addNode prev  ~p~n", [NUMBER, PID]),PID ! {connectOk, prev, self()},
      NEXT ! {addNode, PID, pprev},
      addingNode(NUMBER, NEXT, PID, NNEXT, PREV, PID);

    {addNode, PID, pprev} -> io:fwrite("~p received addNode pprev  ~p~n", [NUMBER, PID]),PID ! {connectOk, pprev, self()},
      addingNode(NUMBER, NEXT, PREV, NNEXT, PID, PID);

    %% Suppress node


    %% tests
    test -> io:fwrite("test received on ~p~n", [NUMBER]),
      NEXT ! test;
      %work(NUMBER, NEXT, PREV, NNEXT, PPREV);

    {connected, _} -> work(NUMBER, NEXT, PREV, NNEXT, PPREV);

    X -> io:fwrite("~p received : ~p~n", [NUMBER, X]),
      work(NUMBER, NEXT, PREV, NNEXT, PPREV)

    after 2000 -> work(NUMBER, NEXT, PREV, NNEXT, PPREV)
  end.
