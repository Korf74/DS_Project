%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. Apr 2017 11:00
%%%-------------------------------------------------------------------
-module(local_supervisor).
-author("remi").

-behaviour(supervisor).

%% API
-export([start_link/0, add_node/0, start_ring/0, add_data/1, request_data/1, size/0
  ,remove_node/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type, Args), {I, {I, start_link, Args}, permanent, 5000, Type, [I]}).

%%%===================================================================
%%% API functions
%%%===================================================================
add_node() ->
  [{_, Pid, _, _} | _] = supervisor:which_children(?MODULE),
  [{_, ChildPid, _, _} | _] = supervisor:which_children(Pid),
  Ret = supervisor:start_child(?MODULE, [ChildPid]),
  io:fwrite("test~n"),
  Ret.

remove_node() ->
  [{_, Pid, _, _} | _] = supervisor:which_children(?MODULE),
  [{_, ChildPid, _, _} | _] = supervisor:which_children(Pid),
  gen_statem:call(ChildPid, stop), % TODO check reply
  io:fwrite("~p~n", [Pid]),
  supervisor:terminate_child(?MODULE, Pid).

start_ring() ->
  {ok, Pid} = supervisor:start_child(?MODULE, [singleton]).

add_data(Data) ->
  [{_, Pid, _, _} | _] = supervisor:which_children(?MODULE),
  [{_, ChildPid, _, _} | _] = supervisor:which_children(Pid),
  gen_statem:call(ChildPid, {newData, Data}).

request_data(Uid) ->
  [{_, Pid, _, _} | _] = supervisor:which_children(?MODULE),
  [{_, ChildPid, _, _} | _] = supervisor:which_children(Pid),
  gen_statem:call(ChildPid, {requestData, Uid}).

size() ->
  [{_, Pid, _, _} | _] = supervisor:which_children(?MODULE),
  [{_, ChildPid, _, _} | _] = supervisor:which_children(Pid),
  gen_statem:call(ChildPid, size).

%%--------------------------------------------------------------------
%% @doc
%% Starts the supervisor
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
  %supervisor:start_link({local, ?SERVER}, ?MODULE, []).
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a supervisor is started using supervisor:start_link/[2,3],
%% this function is called by the new process to find out about
%% restart strategy, maximum restart frequency and child
%% specifications.
%%
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
  {ok, {SupFlags :: {RestartStrategy :: supervisor:strategy(),
    MaxR :: non_neg_integer(), MaxT :: non_neg_integer()},
    [ChildSpec :: supervisor:child_spec()]
  }} |
  ignore |
  {error, Reason :: term()}).
init([]) ->
  RestartStrategy = simple_one_for_one,
  MaxRestarts = 1000,
  MaxSecondsBetweenRestarts = 3600,

  SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

  Restart = transient, % restart only if error
  Shutdown = 2000,
  Type = supervisor,

  AChild = {child, {node_supervisor, start_link, []},
    Restart, Shutdown, Type, [node_supervisor]},

  {ok, {SupFlags, [AChild]}}.
%%%===================================================================
%%% Internal functions
%%%===================================================================
