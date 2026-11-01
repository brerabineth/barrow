#!/usr/bin/env escript
%% barrow test runner: escript test/run.escript [path-to-barrow]
%% runs the built-in battery and then the real command line end to end.

main(Args) ->
    Here = filename:dirname(escript:script_name()),
    Root = filename:dirname(Here),
    Barrow = case Args of
                 [B | _] -> B;
                 [] -> filename:join(Root, "barrow")
             end,
    BB = list_to_binary(Barrow),

    {P, F} = lists:foldl(fun(Ck, Acc) -> Ck(Acc) end, {0, []}, [
        fun({PA, FA}) ->
            {Out, Code} = run(<<BB/binary, " selftest">>),
            io:format("~s", [Out]),
            ck(Code =:= 0 andalso binary:match(Out, <<"PASS">>) =/= nomatch,
               <<"selftest battery">>, {PA, FA})
        end,
        fun({PA, FA}) ->
            Tmp = <<"/tmp/barrow-run-", (integer_to_binary(erlang:unique_integer([positive])))/binary>>,
            {_, Code} = run(<<BB/binary, " forge ", Tmp/binary>>),
            Acc = ck(Code =:= 0, <<"forge runs clean">>, {PA, FA}),

            CleanGit = <<Tmp/binary, "/clean/repo.git">>,
            DirtySite = <<Tmp/binary, "/dirty/site">>,
            {O1, C1} = run(<<BB/binary, " --no-color scan ", CleanGit/binary>>),
            A1 = ck(C1 =:= 0, <<"clean repo exits 0">>, Acc),
            A2 = ck(contains(O1, <<"verdict: clean">>), <<"clean repo verdict clean">>, A1),

            {O2, C2} = run(<<BB/binary, " --no-color scan ", DirtySite/binary>>),
            A3 = ck(C2 =:= 10, <<"dirty repo exits hostile">>, A2),
            A4 = ck(contains(O2, <<"verdict: hostile">>), <<"dirty repo verdict hostile">>, A3),
            A5 = ck(contains(O2, <<"G01">>), <<"autorun hook caught">>, A4),
            A6 = ck(contains(O2, <<"G04">>), <<"filter smudge caught">>, A5),
            A7 = ck(contains(O2, <<"G22">>), <<"secret in history caught">>, A6),

            {O3, _} = run(<<BB/binary, " --json scan ", DirtySite/binary>>),
            A8 = ck(contains(O3, <<"\"verdict\": \"hostile\"">>), <<"json mode keeps the verdict">>, A7),

            {O4, _} = run(<<BB/binary, " --no-color tree ", DirtySite/binary>>),
            A9 = ck(contains(O4, <<".env">>), <<"tree inventories history">>, A8),

            os:cmd("rm -rf " ++ binary_to_list(Tmp)),
            A9
        end
    ]),

    case lists:reverse(F) of
        [] ->
            io:format("run: PASS ~w checks~n", [P]),
            halt(0);
        Fails ->
            io:format("run: FAIL ~w passed, ~w failed~n", [P, length(Fails)]),
            [io:format("  FAIL ~s~n", [X]) || X <- Fails],
            halt(1)
    end.

contains(B, Needle) -> binary:match(B, Needle) =/= nomatch.

ck(true, _Label, {P, F}) -> {P + 1, F};
ck(false, Label, {P, F}) -> {P, [Label | F]}.

run(Cmd) ->
    Port = open_port({spawn_executable, "/bin/sh"},
                     [binary, exit_status, hide, {args, ["-c", binary_to_list(Cmd)]}]),
    collect(Port, <<>>, 0).

collect(Port, Acc, Code) ->
    receive
        {Port, {data, D}} -> collect(Port, <<Acc/binary, D/binary>>, Code);
        {Port, {exit_status, C}} -> {Acc, C}
    after 60000 -> {Acc, Code}
    end.
