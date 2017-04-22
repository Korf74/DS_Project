%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Apr 2017 10:43
%%%-------------------------------------------------------------------
-module(handle_idle).
-author("remi").

%% API
-export([handle/3]).

-include_lib("records.hrl").

handle(cast, start, #singletonState{}) ->
  io:fwrite("~p : initial node~n", [self()]),
  {next_state, work, #singletonState{}};

handle(cast, {connectTo, Pid}, #singletonState{}) ->
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
