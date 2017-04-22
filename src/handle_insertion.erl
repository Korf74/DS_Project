%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Apr 2017 10:50
%%%-------------------------------------------------------------------
-module(handle_insertion).
-author("remi").

%% API
-export([handle/3]).

-include_lib("records.hrl").

handle(cast, {connected, Pid}, [OldState, NewState]) ->
  io:fwrite("~p : node added, ~p -> ~p~n", [self(), OldState, NewState]),
  {next_state, work, NewState};

handle(cast, cancel, [OldState, _]) ->
  {next_state, work, OldState}.
