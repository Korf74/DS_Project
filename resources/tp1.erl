-module(tp1).
-export([max/1, perimeter/1, sort/1, insert/2, map/2, partial/2, multimap/2, multispawn/1, dreturn/2, delegate/1]).

max([]) -> throw("Empty List");
max([X]) -> X;
max([H|LS]) -> erlang:max(H, max(LS)).


perimeter({square, Side}) -> 4 * Side;
perimeter({circle, Radius}) -> 2 * math:pi() * Radius;
perimeter({triangle, A, B, C}) -> A + B + C;
perimeter(_) -> throw("bad argument").

insert(X, []) -> [X];
insert(X, [H|LS]) when X < H  -> [X,H| LS];
insert(X, [H|LS]) -> [H|insert(X, LS)].

sort([]) -> throw("Empty List");
sort([X]) -> [X];
sort([H|LS]) -> insert(H, sort(LS)).

map(_, []) -> throw("Empty List");
map(F, [X]) -> [F(X)];
map(F, [H|LS]) -> [F(H) | map(F, LS)].

partial(F, P1) ->
    (fun(P2) ->
	    F(P1,P2)
    end).

multimap(F, L) ->
     map(partial(fun map/2, F), L).

multispawn(L) ->
    map(fun ({M, F, A}) -> spawn(M, F, A) end, L).

dreturn(Pid, {M, F, A}) ->
    Pid ! {apply(M, F, A), self()}.

delegate(L) ->
    map(
      fun (PID) -> receive {R, PID} -> R end end,
      multispawn(
	     map(
	       fun (T) ->
		       {tp1, dreturn, [self(), T]}
	       end
	       , L
	      )
	    )
	).

dmax(L)->
