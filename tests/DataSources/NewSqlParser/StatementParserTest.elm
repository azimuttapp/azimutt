module DataSources.NewSqlParser.StatementParserTest exposing (..)

import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "StatementParser"
        [ test "aaa" (\_ -> "aaa" |> Expect.equal "aaa")
        ]
