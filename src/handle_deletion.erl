%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Apr 2017 10:50
%%%-------------------------------------------------------------------
-module(handle_deletion).
-author("remi").

%% API
-export([handle/3]).

-include_lib("records.hrl").

handle(cast, removingDone, [Pid, NodeState, State]) ->
  handle_event:handle(cast, removingDone, [Pid, NodeState, State]);

handle(cast, cancel, [_, _, State]) ->
  {next_state, work, State}.