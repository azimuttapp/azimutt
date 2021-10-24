module DataSources.SqlParser.Utils.HelpersTest exposing (..)

import DataSources.SqlParser.TestHelpers.Tests exposing (testParseSql)
import DataSources.SqlParser.Utils.Helpers exposing (buildRawSql, commaSplit, noEnclosingQuotes, parseIndexDefinition)
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Helpers"
        [ describe "parseIndexDefinition"
            [ testParseSql ( parseIndexDefinition, "with DEFERRABLE" )
                "(cost_attribution_category_id, precedence) DEFERRABLE"
                [ "cost_attribution_category_id", "precedence" ]
            ]
        , describe "buildRawSql"
            [ test "basic"
                (\_ ->
                    { head = { line = 11, text = "ALTER TABLE ONLY public.users" }
                    , tail = [ { line = 12, text = "  ADD CONSTRAINT users_id_pkey PRIMARY KEY (id);" } ]
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
            ]
        ]
