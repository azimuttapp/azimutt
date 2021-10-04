module DataSources.NewSqlParser.FileParserTest exposing (..)

import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "FileParser"
        [ test "aaa" (\_ -> "aaa" |> Expect.equal "aaa")
        ]
