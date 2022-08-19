module DataSources.SqlMiner.Utils.HelpersTest exposing (..)

import DataSources.SqlMiner.TestHelpers.Tests exposing (testSql)
import DataSources.SqlMiner.Utils.Helpers exposing (buildRawSql, commaSplit, noEnclosingQuotes, parseIndexDefinition)
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Helpers"
        [ describe "parseIndexDefinition"
            [ testSql ( parseIndexDefinition, "with DEFERRABLE" )
                "(cost_attribution_category_id, precedence) DEFERRABLE"
                [ "cost_attribution_category_id", "precedence" ]
            ]
        , describe "buildRawSql"
            [ test "basic"
                (\_ ->
                    { head = { index = 11, text = "ALTER TABLE ONLY public.users" }
                    , tail = [ { index = 12, text = "  ADD CONSTRAINT users_id_pkey PRIMARY KEY (id);" } ]
                    }
                        |> buildRawSql
                        |> Expect.equal "ALTER TABLE ONLY public.users\n  ADD CONSTRAINT users_id_pkey PRIMARY KEY (id);"
                )
            ]
        , describe "noEnclosingQuotes"
            [ test "double quote" (\_ -> noEnclosingQuotes "\"aaa\"" |> Expect.equal "aaa")
            , test "single quote" (\_ -> noEnclosingQuotes "'aaa'" |> Expect.equal "aaa")
            , test "back quote" (\_ -> noEnclosingQuotes "`aaa`" |> Expect.equal "aaa")
            , test "brackets" (\_ -> noEnclosingQuotes "[aaa]" |> Expect.equal "aaa")
            , test "extra info" (\_ -> noEnclosingQuotes "`aaa`(42)" |> Expect.equal "aaa")
            ]
        , describe "commaSplit"
            [ test "split on comma" (\_ -> commaSplit "aaa,bbb,ccc" |> Expect.equal [ "aaa", "bbb", "ccc" ])
            , test "ignore comma inside parenthesis" (\_ -> commaSplit "aaa,bbb(1,2),ccc" |> Expect.equal [ "aaa", "bbb(1,2)", "ccc" ])
            , test "ignore comma inside quotes" (\_ -> commaSplit "aaa,bbb'1,2',ccc" |> Expect.equal [ "aaa", "bbb'1,2'", "ccc" ])
            , test "ignore comma inside double quotes" (\_ -> commaSplit "aaa,bbb\"1,2\",ccc" |> Expect.equal [ "aaa", "bbb\"1,2\"", "ccc" ])
            , test "ignore quote inside double quotes" (\_ -> commaSplit "aaa,bbb\"l'aaa\",ccc" |> Expect.equal [ "aaa", "bbb\"l'aaa\"", "ccc" ])
            , test "ignore double quote inside quotes" (\_ -> commaSplit "aaa,bbb'l\"aaa',ccc" |> Expect.equal [ "aaa", "bbb'l\"aaa'", "ccc" ])
            ]
        ]
