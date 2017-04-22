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
  end;

handle({newData, Data}, State) ->
  Uid = crypto:hash(md5, Data),
  file:write_file(Uid, Data),
  Uid;

handle({requestData, From, Visited, Uid}, State) ->
  case lists:member(self(), Visited) of
    true -> gen_statem:reply(From, notfound);

    false ->
      Data = retrieveData(State),
      case findUid(Data, Uid) of
        notfound ->
          requestDataNext(From, Visited, Uid, State);

        found ->
          RetData = file:read_file(Uid),
          case RetData of
            {error, _} -> gen_statem:reply(From, notfound);
            {ok, Binary} -> gen_statem:reply(From, {found, Binary})
          end
      end

  end;

handle({size, From, N, Visited}, State) ->
  sendMsgNext(Visited, {size, From, N + 1, [self() | Visited]}, {gen_statem, reply, [From, N]}, State).

%% INTERNAL
retrieveData(State) ->
  case State of
    #singletonState{data=Data} -> Data;
    #pairState{data=Data} -> Data;
    #tripletState{data=Data} -> Data;
    #genState{data=Data} -> Data
  end.

findUid([], _) ->
  notfound;

findUid([H | _], Uid) when H == Uid-> found;

findUid([H | Data], Uid) -> findUid(Data, Uid).

requestDataNext(From, Visited, Uid, State) ->
  case State of
    #singletonState{} ->
      gen_statem:reply(From, notfound);

    #pairState{peer=Next} ->
      gen_statem:cast(Next, {requestData, From, [self() | Visited], Uid});

    #tripletState{next=Next} ->
      gen_statem:cast(Next, {requestData, From, [self() | Visited], Uid});

    #genState{next=Next} ->
      gen_statem:cast(Next, {requestData, From, [self() | Visited], Uid})
  end.

sendMsgNext(Visited, Msg, {M, F, A}, State) ->
  case lists:member(self(), Visited) of
    true -> apply(M, F, A);
    false ->
      case State of
        #singletonState{} -> apply(M, F, A);

        #pairState{peer=Next} ->
          gen_statem:cast(Next, Msg);

        #tripletState{next=Next} ->
          gen_statem:cast(Next, Msg);

        #genState{next=Next} ->
          gen_statem:cast(Next, Msg)
      end
  end.