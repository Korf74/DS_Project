%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Apr 2017 10:53
%%%-------------------------------------------------------------------
-module(handle_message).
-author("remi").

%% API
-export([handle/2]).

-include_lib("records.hrl").

handle({testToken, Init}, #singletonState{}) ->
  Init ! {testTokenAck, self()};

handle({testToken, Init}, #pairState{peer=Peer}) ->
  gen_statem:cast(Peer, {testToken, Init}),
  Init ! {testTokenAck, self()};

handle({testToken, Init}, #tripletState{next=Next}) ->
  gen_statem:cast(Next, {testToken, Init}),
  Init ! {testTokenAck, self()};

handle({testToken, Init}, #genState{next=Next}) ->
  gen_statem:cast(Next, {testToken, Init}),
  Init ! {testTokenAck, self()};

handle({testScatter, []}, State) ->
  ok;

handle({testScatter, [Top | Msgs]}, State) ->
  io:fwrite("~p : received test scatter with top \"~p\"~n", [self(), Top]),
  case State of
    #singletonState{} ->
      gen_statem:cast(self(), {testScatter, Msgs});

    #pairState{peer=Peer} ->
      gen_statem:cast(Peer, {testScatter, Msgs});

    #tripletState{next=Next, prev=Prev} ->
      gen_statem:cast(Next, {testScatter, Msgs});

    #genState{nnext=Nnext, next=Next, prev=Prev, pprev=Pprev} ->
      gen_statem:cast(Next, {testScatter, Msgs})
  end.