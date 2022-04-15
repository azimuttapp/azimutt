module DataSources.AmlParser.AmlParserTest exposing (..)

import DataSources.AmlParser.AmlParser exposing (parse)
import DataSources.AmlParser.TestHelpers exposing (testParse)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "AmlParser"
        [ describe "table"
            [ testParse ( "empty", parse )
                ""
                []

            --, testParse ( "name only", parse )
            --    "users"
            --    [ { schema = Nothing, table = "users" } ]
            ]
        ]
