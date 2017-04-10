%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Apr 2017 17:30
%%%-------------------------------------------------------------------
-module(node_statem).
-author("remi").

-behaviour(gen_statem).

%% API
-export([start_link/0, connectTo/1, disconnect/0]).

%% gen_statem callbacks
-export([
  callback_mode/0,
  init/1,
  work/3,
  idle/3,
  addingNode/3,
  removingNode/3,
  format_status/2,
  terminate/3,
  code_change/4
]).

-record(singletonState, {}).

-record(pairState, {
  peer}).

-record(tripletState, {
  next,
  prev}).

-record(genState, {
  nnext=self(),
  next=self(),
  prev=self(),
  pprev=self()}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
  {ok, PID} = gen_statem:start_link(?MODULE, [], []),
  PID.

connectTo(Pid) ->
  gen_statem:cast(self(), {connectTo, Pid}),
  io:fwrite("~p connected to ~p~n", [self(), Pid]).

disconnect() ->
  io:fwrite("~p disconnecting~n", [self()]),
  gen_statem:cast(self(), stop).



%%%===================================================================
%%% gen_statem callbacks
%%%===================================================================

callback_mode() ->
  state_functions.

init([]) ->
  {ok, idle, #singletonState{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Called (1) whenever sys:get_status/1,2 is called by gen_statem or
%% (2) when gen_statem terminates abnormally.
%% This callback is optional.
%%
%% @spec format_status(Opt, [PDict, StateName, State]) -> term()
%% @end
%%--------------------------------------------------------------------
format_status(_Opt, [_PDict, _StateName, _State]) ->
  {
    _StateName,
    _State
  }.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% There should be one instance of this function for each possible
%% state name.  If callback_mode is statefunctions, one of these
%% functions is called when gen_statem receives and event from
%% call/2, cast/2, or as a normal process message.
%%
%% @spec state_name(Event, From, State) ->
%%                   {next_state, NextStateName, NextState} |
%%                   {next_state, NextStateName, NextState, Actions} |
%%                   {stop, Reason, NewState} |
%%    				 stop |
%%                   {stop, Reason :: term()} |
%%                   {stop, Reason :: term(), NewData :: data()} |
%%                   {stop_and_reply, Reason, Replies} |
%%                   {stop_and_reply, Reason, Replies, NewState} |
%%                   {keep_state, NewData :: data()} |
%%                   {keep_state, NewState, Actions} |
%%                   keep_state_and_data |
%%                   {keep_state_and_data, Actions}
%% @end
%%--------------------------------------------------------------------
idle(cast, start, #singletonState{}) ->
  io:fwrite("~p : initial node~n", [self()]),
  {next_state, work, #singletonState{}};

idle(cast, {connectTo, Pid}, #singletonState{}) ->
  Reply = gen_statem:call(Pid, insertion_request),
  case Reply of
    {become, Next_State, New_State} ->
      Msg = {connected, self()},
      case New_State of
        #genState{nnext=Nnext, next=Next, prev=Prev, pprev=Nnext} ->
          gen_statem:cast(Nnext, Msg),
          gen_statem:cast(Next, Msg),
          gen_statem:cast(Prev, Msg);
        #genState{nnext=Nnext, next=Next, prev=Prev, pprev=Pprev} ->
          gen_statem:cast(Nnext, Msg),
          gen_statem:cast(Next, Msg),
          gen_statem:cast(Prev, Msg),
          gen_statem:cast(Pprev, Msg);
        #tripletState{next=Next, prev=Prev} ->
          gen_statem:cast(Next, Msg),
          gen_statem:cast(Prev, Msg);
        #pairState{peer=Peer} ->
          gen_statem:cast(Peer, Msg)
      end,
      io:fwrite("~p : connected as ~p~n", [self(), New_State]),
      {next_state, Next_State, New_State};
    _ -> keep_state_and_Data
  end.

work({call, From}, {addingNode, List, Pid},
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

work({call, From}, {addingNode, NewState}, State) ->
  {next_state, addingNode, [State, NewState],
    [{reply, From, ok}]};

work({call, From}, {removingNode, #pairState{peer=NodePeer}},
    OldState=#pairState{peer=Peer}) when NodePeer == self() ->
  io:fwrite("~p : node removed, ~p -> ~p~n", [self(), OldState, #singletonState{}]),
  gen_statem:reply(From, ok),
  {next_state, work, #singletonState{}};

work({call, From}, {removingNode, NodeState}, State) ->
  gen_statem:reply(From, ok),
  {next_state, removingNode, [element(1, From), NodeState, State]};

work({call, From}, insertion_request, State) ->
  handle_event({call, From}, insertion_request, State);

work(cast, stop, State) ->
  io:fwrite("~p : received stop~n", [self()]),
  handle_event(cast, stop, State);

work(cast, {testToken, Init}, State) ->
  handle_message({testToken, Init}, State),
  stop;

work(cast, Msg, State) ->
  handle_message(Msg, State),
  keep_state_and_data.

addingNode(cast, {connected, Pid}, [OldState, NewState]) ->
  io:fwrite("~p : node added, ~p -> ~p~n", [self(), OldState, NewState]),
  {next_state, work, NewState};

addingNode(cast, cancel, [OldState, _]) ->
  {next_state, work, OldState}.

removingNode(cast, removingDone, [Pid, NodeState, State]) ->
  handle_event(cast, removingDone, [Pid, NodeState, State]);

removingNode(cast, cancel, [_, _, State]) ->
  {next_state, work, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_statem when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_statem terminates with
%% Reason. The return value is ignored.
%%
%% @spec terminate(Reason, StateName, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _StateName, _State) -> ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, StateName, State, Extra) ->
%%                   {ok, StateName, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, StateName, State, _Extra) ->
  {ok, StateName, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
handle_message({testToken, Init}, #singletonState{}) ->
  Init ! {testTokenAck, self()};

handle_message({testToken, Init}, #pairState{peer=Peer}) ->
  gen_statem:cast(Peer, {testToken, Init}),
  Init ! {testTokenAck, self()};

handle_message({testToken, Init}, #tripletState{next=Next}) ->
  gen_statem:cast(Next, {testToken, Init}),
  Init ! {testTokenAck, self()};

handle_message({testToken, Init}, #genState{next=Next}) ->
  gen_statem:cast(Next, {testToken, Init}),
  Init ! {testTokenAck, self()}.

handle_event({call, From}, insertion_request, #singletonState{}) ->
  gen_statem:reply(From, {become, work, #pairState{peer=self()}}),

  {next_state, addingNode, [#singletonState{}, #pairState{peer=element(1, From)}]};

handle_event({call, From}, insertion_request,
    State=#pairState{peer=Peer}) ->
  gen_statem:call(Peer, {addingNode, #tripletState{next=self(), prev=element(1, From)}}),
  gen_statem:reply(From, {become, work,
    #tripletState{next=Peer, prev=self()}}),

  {next_state, addingNode, [State, #tripletState{next=element(1, From), prev=Peer}]};

handle_event({call, From}, insertion_request,
    State=#tripletState{next=Next, prev=Prev}) ->
  gen_statem:call(Next, {addingNode,
    #genState{nnext=self(), next=Prev, prev=element(1, From), pprev=self()}}),
  gen_statem:call(Prev, {addingNode,
    #genState{nnext=element(1, From), next=self(), prev=Next, pprev=element(1, From)}}),
  gen_statem:reply(From, {become, work,
    #genState{nnext=Prev, next=Next, prev=self(), pprev=Prev}}),

    {next_state, addingNode,
      [State, #genState{nnext=Next, next=element(1, From), prev=Prev, pprev=Next}]};


handle_event({call, From}, insertion_request,
    State=#genState{next=Next, prev=Prev, pprev=Pprev}) ->
  [NodeNnext, NodeNext, NodePrev, NodePprev] =
    gen_statem:call(Next, {addingNode, [self()], element(1, From)}),

  gen_statem:reply(From, {become, work,
    #genState{nnext=NodeNnext, next=NodeNext, prev=NodePrev, pprev=NodePprev}}),

  {next_state, addingNode,
    [State, #genState{nnext=element(1, From), next=Next, prev=Prev, pprev=Pprev}]};

handle_event(cast, stop, #singletonState{}) ->
  stop;

handle_event(cast, stop, State=#pairState{peer=Peer}) ->
  gen_statem:call(Peer, {removingNode, State}),
  stop;

handle_event(cast, stop, State=#tripletState{next=Next, prev=Prev}) ->
  gen_statem:call(Next, {removingNode, State}),
  gen_statem:call(Prev, {removingNode, State}),

  gen_statem:cast(Next, removingDone),
  gen_statem:cast(Prev, removingDone),
  stop;

handle_event(cast, stop,
    State=#genState{nnext=Nnext, next=Next, prev=Prev, pprev=Nnext}) ->
  gen_statem:call(Nnext, {removingNode, State}),
  gen_statem:call(Next, {removingNode, State}),
  gen_statem:call(Prev, {removingNode, State}),

  gen_statem:cast(Nnext, removingDone),
  gen_statem:cast(Next, removingDone),
  gen_statem:cast(Prev, removingDone),
  stop;

handle_event(cast, stop,
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

handle_event(cast, removingDone,
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

handle_event(cast, removingDone,
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

handle_event(cast, removingDone,
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

