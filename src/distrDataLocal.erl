%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. Apr 2017 22:38
%%%-------------------------------------------------------------------
-module(distrDataLocal).
-author("remi").

-behaviour(application).

% API
-export([addNode/0, startRing/0, addData/1, requestData/1, size/0, removeNode/0]).

%% Application callbacks
-export([start/2,
  stop/1]).

%%%===================================================================
%%% API functions
%%%===================================================================
%% TODO

%% LOCAL
addNode() ->
  local_supervisor:add_node().

removeNode() ->
  local_supervisor:remove_node().

startRing() ->
  local_supervisor:start_ring().

addData(Data) ->
  local_supervisor:add_data(Data).

requestData(Uid) ->
  local_supervisor:request_data(Uid).

size() ->
  local_supervisor:size().

%%%===================================================================
%%% Application callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called whenever an application is started using
%% application:start/[1,2], and should start the processes of the
%% application. If the application is structured according to the OTP
%% design principles as a supervision tree, this means starting the
%% top supervisor of the tree.
%%
%% @end
%%--------------------------------------------------------------------
-spec(start(StartType :: normal | {takeover, node()} | {failover, node()},
    StartArgs :: term()) ->
  {ok, pid()} |
  {ok, pid(), State :: term()} |
  {error, Reason :: term()}).
start(_StartType, _StartArgs) ->
  case local_supervisor:start_link() of
    {ok, Pid} ->
      {ok, Pid};
    Error ->
      Error
  end.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called whenever an application has stopped. It
%% is intended to be the opposite of Module:start/2 and should do
%% any necessary cleaning up. The return value is ignored.
%%
%% @end
%%--------------------------------------------------------------------
-spec(stop(State :: term()) -> term()).
stop(_State) ->
  ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================
