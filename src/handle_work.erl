%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Apr 2017 10:45
%%%-------------------------------------------------------------------
-module(handle_work).
-author("remi").

%% API
-export([handle/3]).

-include_lib("records.hrl").

handle({call, From}, {addingNode, List, Pid},
    State=#genState{nnext=Nnext, next=Next, prev=Prev, pprev=Pprev}) ->
  case length(List) of
    3 ->
      gen_statem:reply(From, [self() | List]),
      {next_state, addingNode,
        [
          State,
          #genState{nnext=Nnext, next=Next, prev=Prev, pprev=Pid}
        ]
      };
    2 ->
      Polled = gen_statem:call(Next, {addingNode, [self() | List], Pid}),
      gen_statem:reply(From, Polled),
      {next_state, addingNode,
        [
          State,
          #genState{nnext=Nnext, next=Next, prev=Pid, pprev=Prev}
        ]
      };
    1 ->
      Polled = gen_statem:call(Next, {addingNode, [self() | List], Pid}),
      gen_statem:reply(From, Polled),
      {next_state, addingNode,
        [
          State,
          #genState{nnext=Next, next=Pid, prev=Prev, pprev=Pprev}
        ]}
  end;

handle({call, From}, {addingNode, NewState}, State) ->
  {next_state, addingNode, [State, NewState],
    [{reply, From, ok}]};

handle({call, From}, {removingNode, #pairState{peer=NodePeer}},
    OldState=#pairState{}) when NodePeer == self() ->
  io:fwrite("~p : node removed, ~p -> ~p~n", [self(), OldState, #singletonState{}]),
  gen_statem:reply(From, ok),
  {next_state, work, #singletonState{}};

handle({call, From}, {removingNode, NodeState}, State) ->
  gen_statem:reply(From, ok),
  {next_state, removingNode, [element(1, From), NodeState, State]};

handle({call, From}, insertion_request, State) ->
  handle_event:handle({call, From}, insertion_request, State);

handle(cast, stop, State) ->
  io:fwrite("~p : received stop~n", [self()]),
  handle_event:handle(cast, stop, State);

%% for testing
handle(cast, {testToken, Init}, State) ->
  handle_message:handle({testToken, Init}, State),
  stop;

handle(cast, {testScatter, Msgs}, State) ->
  handle_message:handle({testScatter, Msgs}, State),
  stop;

handle(cast, {broadcast, Msg}, State) ->
  handle_message:handle(Msg, State),
  keep_state_and_data;

handle(cast, {scatter, Msgs}, State) ->
  handle_message:handle(Msgs, State),
  keep_state_and_data.
