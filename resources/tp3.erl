-module(tp3).
-export([empty/0, empty/1, send/5, new_s/2, process/6, main/0]).

pi()        -> array:from_list([3,1,4,1,5,9,2,6,5,3,5,8,9,7,9,3,2,3,8,4,6,2,6,4,3,3,8,3,2,7,9,5,0,2,8,8,4,1,9,7,1,6,9,3,9,9,3,7,5,1,0,5,8,2,0,9,7,4,9,4,4,5,9,2,3,0,7,8,1,6,4,0,6,2,8,6,2,0,8,9,9,8,6,2,8,0,3,4,8,2,5,3,4,2,1,1,7,0,6,7]).
phi()       -> array:from_list([1,6,1,8,0,3,3,9,8,8,7,4,9,8,9,4,8,4,8,2,0,4,5,8,6,8,3,4,3,6,5,6,3,8,1,1,7,7,2,0,3,0,9,1,7,9,8,0,5,7,6,2,8,6,2,1,3,5,4,4,8,6,2,2,7,0,5,2,6,0,4,6,2,8,1,8,9,0,2,4,4,9,7,0,7,2,0,7,2,0,4,1,8,9,3,9,1,1,3,7]).
empty()     -> array:new({default, undefined}).
empty(Size) -> array:new(Size, {default, undefined}).

send(PID, AR, A, S, L) ->
    %io:fwrite("~p : ~p~n", [self(), array:to_list(AR)]),
    I = erlang:min(array:size(AR) - 1, rand:uniform(S + L - A) - 1),
    io:fwrite("~p sends ~p~n", [self(), {array:get(I, AR), I}]),
    PID ! {array:get(I, AR), I}.

new_s(OUT, I) ->

    case array:get(I, OUT) of
	undefined ->
	    I;
	_ -> new_s(OUT, I + 1)
    end.

process(PID, S, A, IN, OUT, L) ->
io:fwrite("~p : ~p~n", [self(), array:to_list(OUT)]),
io:fwrite("~p : a : ~p, s : ~p, l : ~p~n", [self(), A, S, L]),
    case rand:uniform(2) of
	1 -> send(PID, IN, A, S, L),
	     process(PID, S, A, IN, OUT, L);
	2 -> receive
		 {W, I} -> io:fwrite("~p received ~p~n", [self(), {W, I}]),
			   case array:get(I, OUT) of
			       undefined -> process(PID, new_s(OUT, 0), erlang:max(A, I - L + 1), IN, array:set(I, W, OUT), L);
			       _ -> process(PID, S, A, IN, OUT, L)
			   end
		 after 100 -> process(PID, S, A, IN, OUT, L)
	     end
    end.


main() ->
    PID = spawn(tp3, process, [self(), 0, 0, pi(), empty(), 5]),
    process(PID, 0, 0, phi(), empty(), 5).
