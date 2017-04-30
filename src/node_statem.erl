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
-export([start_link/0, start_link1/1, start_ring/0, start_link1/0, start_link_singleton/0,
  connectTo/1, disconnect/0]).

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

-include_lib("records.hrl").

%%%===================================================================
%%% API
%%%===================================================================
start_link() ->
  % to change to {local/global, ?SERVER}
  gen_statem:start_link({local, ?MODULE}, ?MODULE, [], []).

start_link1() ->
  % to change to {local/global, ?SERVER}
  gen_statem:start_link({local, ?MODULE}, ?MODULE, [], []).

start_link1(Pid) ->
  {ok, ChildPid} = gen_statem:start_link(?MODULE, [], []),
  io:fwrite("~p~n", [ChildPid]),
  gen_statem:cast(ChildPid, {connectTo, Pid}),
  io:fwrite("~p connected to ~p~n", [ChildPid, Pid]),
  {ok, ChildPid}.

start_link_singleton() ->
  gen_statem:start_link(?MODULE, [singleton], []).

connectTo(Pid) ->
  gen_statem:cast(self(), {connectTo, Pid}),
  io:fwrite("~p connected to ~p~n", [self(), Pid]).

disconnect() ->
  io:fwrite("~p disconnecting~n", [self()]),
  gen_statem:cast(self(), stop).

start_ring() ->
  gen_statem:cast(whereis(?MODULE), start).



%%%===================================================================
%%% gen_statem callbacks
%%%===================================================================

callback_mode() ->
  state_functions.

init([singleton]) ->
  io:fwrite("~p : init and work~n", [self()]),
  {ok, work, #singletonState{}};

init([]) ->
  io:fwrite("~p : init~n", [self()]),
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
idle(Event, Msg, State) ->
  handle_idle:handle(Event, Msg, State).

work(Event, Msg, State) ->
  handle_work:handle(Event, Msg, State).

addingNode(Event, Msg, State) ->
  handle_insertion:handle(Event, Msg, State).

removingNode(Event, Msg, State) ->
  handle_deletion:handle(Event, Msg, State).

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

