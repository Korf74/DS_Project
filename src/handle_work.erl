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

handle({call, From}, {newData, Data}, State) ->
  Uid = handle_message:handle({newData, Data}, State),
  NewState = stateDataUpdate(State, Uid),
  gen_statem:reply(From, Uid),
  {keep_state, NewState};

handle({call, From}, {requestData, Uid}, State) ->
  handle_message:handle({requestData, From, [], Uid}, State),
  keep_state_and_data;

handle({call, From}, size, State) ->
  handle_message:handle({size, From, 0, []}, State),
  keep_state_and_data;

handle({call, From}, stop, State) ->
  io:fwrite("~p : received stop~n", [self()]),
  handle_event:handle({call, From}, stop, State);

%% for testing
handle(cast, {testToken, Init}, State) ->
  handle_message:handle({testToken, Init}, State),
  stop;

handle(cast, {testScatter, Msgs}, State) ->
  handle_message:handle({testScatter, Msgs}, State),
  stop;

% Normal messages, i.e. that don't need state or topology change
handle(cast, Msg, State) ->
  handle_message:handle(Msg, State),
  keep_state_and_data.

%% INTERNAL
stateDataUpdate(State=#singletonState{data=Data}, Uid) ->
  State#singletonState{data=[Uid | Data]};

stateDataUpdate(State=#pairState{data=Data}, Uid) ->
  State#pairState{data=[Uid | Data]};

stateDataUpdate(State=#tripletState{data=Data}, Uid) ->
  State#tripletState{data=[Uid | Data]};

stateDataUpdate(State=#genState{data=Data}, Uid) ->
  State#genState{data=[Uid | Data]}.

