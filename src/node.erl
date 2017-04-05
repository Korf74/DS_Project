%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Apr 2017 19:03
%%%-------------------------------------------------------------------
-module(node).
-author("remi").

%% API
-export([idle/0]).

idle() ->
  receive
    {connectTo, PID} ->
      PID ! {addNode, self()},
      receive
        {become, _, MODULE, FUN, ARGS} ->
          case MODULE of
            genRing ->
              lists:foreach(fun (X) -> X ! {connected, self()} end, ARGS);
            _ ->
              PID ! {connected, self()}
          end,
          apply(MODULE, FUN, ARGS)
      end
  end.
