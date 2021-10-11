module DataSources.NewSqlParser.Parsers.HelpersTest exposing (..)

import DataSources.NewSqlParser.Parsers.Helpers exposing (quotedParser)
import Expect
import Parser
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Helpers"
        [ describe "quotedParser"
            [ test "brackets" (\_ -> "[text]" |> Parser.run (quotedParser '[' ']') |> Expect.equal (Ok "text"))
            , test "backquotes" (\_ -> "`text`" |> Parser.run (quotedParser '`' '`') |> Expect.equal (Ok "text"))
            ]
        ]
