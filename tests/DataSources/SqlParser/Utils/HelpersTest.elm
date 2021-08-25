module DataSources.SqlParser.Utils.HelpersTest exposing (..)

import DataSources.SqlParser.Utils.Helpers exposing (buildRawSql, commaSplit)
import DataSources.SqlParser.Utils.Types exposing (SqlStatement)
import Expect
import Test exposing (Test, describe, test)


fileName : String
fileName =
    "file.sql"


suite : Test
suite =
    describe "Helpers"
        [ describe "buildRawSql"
            [ test "basic"
                (\_ ->
                    buildRawSql
                        { head = { file = fileName, line = 11, text = "ALTER TABLE ONLY public.users" }
                        , tail = [ { file = fileName, line = 12, text = "  ADD CONSTRAINT users_id_pkey PRIMARY KEY (id);" } ]
                        }
                        |> Expect.equal "ALTER TABLE ONLY public.users   ADD CONSTRAINT users_id_pkey PRIMARY KEY (id);"
                )
            ]
        , describe "commaSplit"
            [ test "split on comma" (\_ -> commaSplit "aaa,bbb,ccc" |> Expect.equal [ "aaa", "bbb", "ccc" ])
            , test "ignore comma inside parenthesis" (\_ -> commaSplit "aaa,bbb(1,2),ccc" |> Expect.equal [ "aaa", "bbb(1,2)", "ccc" ])
            ]
        ]


stmCheck : String -> String -> (SqlStatement -> Result e a) -> (SqlStatement -> Result e a) -> Test
stmCheck name sql func result =
    let
        statement : SqlStatement
        statement =
            { head = { file = "", line = 0, text = sql }, tail = [] }
    in
    test name (\_ -> func statement |> Expect.equal (result statement))
