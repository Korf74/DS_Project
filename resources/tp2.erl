-module(tp2).
-export([token2_process/1, token2/1, tokenN_process/1, tokenN_spawn/2, tokenN/2]).

token2_process(PID) ->
    receive
	0 -> ok;

	N ->
	    PID ! (N - 1),
	    io:fwrite("~p received ~p~n", [self(), N]),
	    token2_process(PID)
    end.

token2(M) ->
    PID = spawn(tp2, token2_process, [self()]),
    PID ! M,
    token2_process(PID),
    {PID, self()}.

tokenN_process(PID) ->
    receive
	{0, PID} ->
	    io:fwrite("~p received 0 and stops ~n", [self()]),
	    ok;

	{0, PID_STOP} ->
	    io:fwrite("~p received 0 and stops ~n", [self()]),
	    PID ! {0, PID_STOP};

	0 -> PID ! {0, self()};

	N ->
	    PID ! (N - 1),
	    io:fwrite("~p received ~p~n", [self(), N]),
	    tokenN_process(PID)
    end.

tokenN_spawn(0, PID_FIRST) ->
    tokenN_process(PID_FIRST);

tokenN_spawn(N, PID_FIRST) ->
    PID = spawn(tp2, tokenN_spawn, [N - 1, PID_FIRST]),
    tokenN_process(PID).

tokenN(2, M) -> token2(M);

tokenN(N, M) ->
    PID = spawn(tp2, tokenN_spawn, [N - 1, self()]),
    PID ! M,
    tokenN_process(PID).

tokenN_star_process(PID) ->
    receive
	0 -> PID ! 0;
	N -> PID ! N - 1
    end.

tokenN_star_spawn(1) -> [spawn(tp1, tokenN_star_process, [self()])];

tokenN_star_spawn(N) -> [spawn(tp1, tokenN_star_process, [self()]) | tokenN_star_spawn(N - 1)].

tokenN_star_loop([PID | PIDs], N, M) ->
%%%

tokenN_star(N, M) ->
    PIDs = tokenN_star_spawn(N),
    tokenN_star_loop(PIDs, N, M).
