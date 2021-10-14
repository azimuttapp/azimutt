module Libs.ParserTest exposing (..)

import Expect
import Libs.Parser exposing (quotedParser)
import Parser
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Parser"
        [ describe "quotedParser"
            [ test "brackets" (\_ -> "[text]" |> Parser.run (quotedParser '[' ']') |> Expect.equal (Ok "text"))
            , test "backquotes" (\_ -> "`text`" |> Parser.run (quotedParser '`' '`') |> Expect.equal (Ok "text"))
            ]
        ]
