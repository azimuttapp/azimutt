module DataSources.AmlParser.TestHelpers exposing (testParse, testParser)

import Expect
import Parser exposing (Parser)
import Test exposing (Test, test)


testParse : ( String, String -> Result e a ) -> String -> a -> Test
testParse ( name, parse ) aml result =
    test name (\_ -> aml |> parse |> Expect.equal (Ok result))


testParser : ( String, Parser a ) -> String -> a -> Test
testParser ( name, parser ) input result =
    test name (\_ -> input |> Parser.run parser |> Expect.equal (Ok result))
