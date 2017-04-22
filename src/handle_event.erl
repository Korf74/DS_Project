%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Apr 2017 10:55
%%%-------------------------------------------------------------------
-module(handle_event).
-author("remi").

%% API
-export([handle/3]).

-include_lib("records.hrl").

handle({call, From}, insertion_request, #singletonState{}) ->
  gen_statem:reply(From, {become, work, #pairState{peer=self()}}),

  {next_state, addingNode, [#singletonState{}, #pairState{peer=element(1, From)}]};

handle({call, From}, insertion_request,
    State=#pairState{peer=Peer}) ->
  gen_statem:call(Peer, {addingNode, #tripletState{next=self(), prev=element(1, From)}}),
  gen_statem:reply(From, {become, work,
    #tripletState{next=Peer, prev=self()}}),

  {next_state, addingNode, [State, #tripletState{next=element(1, From), prev=Peer}]};

handle({call, From}, insertion_request,
    State=#tripletState{next=Next, prev=Prev}) ->
  gen_statem:call(Next, {addingNode,
    #genState{nnext=self(), next=Prev, prev=element(1, From), pprev=self()}}),
  gen_statem:call(Prev, {addingNode,
    #genState{nnext=element(1, From), next=self(), prev=Next, pprev=element(1, From)}}),
  gen_statem:reply(From, {become, work,
    #genState{nnext=Prev, next=Next, prev=self(), pprev=Prev}}),

  {next_state, addingNode,
    [State, #genState{nnext=Next, next=element(1, From), prev=Prev, pprev=Next}]};


handle({call, From}, insertion_request,
    State=#genState{next=Next, prev=Prev, pprev=Pprev}) ->
  [NodeNnext, NodeNext, NodePrev, NodePprev] =
    gen_statem:call(Next, {addingNode, [self()], element(1, From)}),

  gen_statem:reply(From, {become, work,
    #genState{nnext=NodeNnext, next=NodeNext, prev=NodePrev, pprev=NodePprev}}),

  {next_state, addingNode,
    [State, #genState{nnext=element(1, From), next=Next, prev=Prev, pprev=Pprev}]};

handle(cast, stop, #singletonState{}) ->
  stop;

handle(cast, stop, State=#pairState{peer=Peer}) ->
  gen_statem:call(Peer, {removingNode, State}),
  stop;

handle(cast, stop, State=#tripletState{next=Next, prev=Prev}) ->
  gen_statem:call(Next, {removingNode, State}),
  gen_statem:call(Prev, {removingNode, State}),

  gen_statem:cast(Next, removingDone),
  gen_statem:cast(Prev, removingDone),
  stop;

handle(cast, stop,
    State=#genState{nnext=Nnext, next=Next, prev=Prev, pprev=Nnext}) ->
  gen_statem:call(Nnext, {removingNode, State}),
  gen_statem:call(Next, {removingNode, State}),
  gen_statem:call(Prev, {removingNode, State}),

  gen_statem:cast(Nnext, removingDone),
  gen_statem:cast(Next, removingDone),
  gen_statem:cast(Prev, removingDone),
  stop;

handle(cast, stop,
    State=#genState{nnext=Nnext, next=Next, prev=Prev, pprev=Pprev}) ->
  gen_statem:call(Nnext, {removingNode, State}),
  gen_statem:call(Next, {removingNode, State}),
  gen_statem:call(Prev, {removingNode, State}),
  gen_statem:call(Pprev, {removingNode, State}),

  gen_statem:cast(Nnext, removingDone),
  gen_statem:cast(Next, removingDone),
  gen_statem:cast(Prev, removingDone),
  gen_statem:cast(Pprev, removingDone),
  stop;

handle(cast, removingDone,
    [
      Pid,
      _,
      State=#tripletState{prev=Prev, next=Next}
    ]) ->
  case Pid of
    Prev ->
      NewState=#pairState{peer=Next},
      io:fwrite("~p : node removed, ~p -> ~p~n", [self(), State, NewState]),
      {next_state, work, NewState};

    Next ->
      NewState=#pairState{peer=Prev},
      io:fwrite("~p : node removed, ~p -> ~p~n", [self(), State, NewState]),
      {next_state, work, NewState};
    _ -> {next_state, work, State}
  end;

handle(cast, removingDone,
    [
      Pid,
      #genState{nnext=NodeNnext, next=NodeNext,
        prev=NodePrev, pprev=NodeNnext},
      State=#genState{nnext=Nnext, next=Next,
        prev=Prev, pprev=Nnext}
    ]) ->
  case Pid of
    Nnext ->
      NewState=#tripletState{next=Next, prev=Prev},
      io:fwrite("~p : node removed, ~p -> ~p~n", [self(), State, NewState]),
      {next_state, work, NewState};

    Next ->
      NewState=#tripletState{next=Nnext, prev=Prev},
      io:fwrite("~p : node removed, ~p -> ~p~n", [self(), State, NewState]),
      {next_state, work, NewState};

    Prev ->
      NewState=#tripletState{next=Next, prev=Nnext},
      io:fwrite("~p : node removed, ~p -> ~p~n", [self(), State, NewState]),
      {next_state, work, NewState};

    _ -> {next_state, work, State}
  end;

handle(cast, removingDone,
    [
      Pid,
      #genState{nnext=NodeNnext, next=NodeNext,
        prev=NodePrev, pprev=NodePprev},
      State=#genState{nnext=Nnext, next=Next,
        prev=Prev, pprev=Pprev}
    ]) ->
  case Pid of
    Nnext ->
      NewState=#genState{nnext=NodeNext, next=Next, prev=Prev, pprev=Pprev},
      io:fwrite("~p : node removed, ~p -> ~p~n", [self(), State, NewState]),
      {next_state, work, NewState};

    Next ->
      NewState=#genState{nnext=NodeNnext, next=Nnext, prev=Prev, pprev=Pprev},
      io:fwrite("~p : node removed, ~p -> ~p~n", [self(), State, NewState]),
      {next_state, work, NewState};

    Prev ->
      NewState=#genState{nnext=Nnext, next=Next, prev=Pprev, pprev=NodePprev},
      io:fwrite("~p : node removed, ~p -> ~p~n", [self(), State, NewState]),
      {next_state, work, NewState};

    Pprev ->
      NewState=#genState{nnext=Nnext, next=Next, prev=Prev, pprev=NodePrev},
      io:fwrite("~p : node removed, ~p -> ~p~n", [self(), State, NewState]),
      {next_state, work, NewState};

    _ -> {next_state, work, State}
  end.
