%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. Apr 2017 11:08
%%%-------------------------------------------------------------------
-module(node_supervisor).
-author("remi").

-behaviour(supervisor).

%% API
-export([start_link/0, start_link/1, start_link_singleton/0, connectTo/1, disconnect/0,
  start_ring/0, add_node/1]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================

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

start_link(singleton) ->
  supervisor:start_link(?MODULE, [singleton]);

start_link(Pid) ->
  supervisor:start_link(?MODULE, [Pid]).

start_link_singleton() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, [singleton]).

connectTo(Pid) ->
  whereis(child) ! connectTo(Pid).

disconnect() ->
  whereis(child) ! stop.

start_ring() ->
  node_statem:start_ring().

add_node(Node) ->
  gen_statem:cast({node_statem, Node}, {connectTo, {self()}}).

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

init([singleton]) ->
  RestartStrategy = one_for_one,
  MaxRestarts = 1000,
  MaxSecondsBetweenRestarts = 3600,

  SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

  Restart = transient, % restart only if error
  Shutdown = 2000,
  Type = worker,

  AChild = {child, {node_statem, start_link_singleton, []},
    Restart, Shutdown, Type, [node_statem]},

  {ok, {SupFlags, [AChild]}};


init([Pid]) ->
  RestartStrategy = one_for_one,
  MaxRestarts = 1000,
  MaxSecondsBetweenRestarts = 3600,

  SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

  Restart = transient, % restart only if error
  Shutdown = 2000,
  Type = worker,

  AChild = {child, {node_statem, start_link1, [Pid]},
    Restart, Shutdown, Type, [node_statem]},

  {ok, {SupFlags, [AChild]}};

init([]) ->
  RestartStrategy = one_for_one,
  MaxRestarts = 1000,
  MaxSecondsBetweenRestarts = 3600,

  SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

  Restart = transient, % restart only if error
  Shutdown = 2000,
  Type = worker,

  AChild = {child, {node_statem, start_link, []},
    Restart, Shutdown, Type, [node_statem]},

  {ok, {SupFlags, [AChild]}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

