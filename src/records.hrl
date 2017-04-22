%%%-------------------------------------------------------------------
%%% @author remi
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Apr 2017 10:41
%%%-------------------------------------------------------------------
-author("remi").

-record(singletonState, {
  data=[]
}).

-record(pairState, {
  peer,
  data=[]
}).

-record(tripletState, {
  next,
  prev,
  data=[]
}).

-record(genState, {
  nnext=self(),
  next=self(),
  prev=self(),
  pprev=self(),
  data=[]
}).
