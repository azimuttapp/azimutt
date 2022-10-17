module Libs.RegexTest exposing (..)

import Expect
import Libs.Regex as Regex
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Regex"
        [ describe "contains"
            [ test "basic" (\_ -> "a END)" |> Regex.matchI "[^A-Z]END[^A-Z]" |> Expect.equal True)
            , test "basic 2" (\_ -> "a ENDe" |> Regex.matchI "[^A-Z]END[^A-Z]" |> Expect.equal False)
            ]
        , describe "replace"
            [ test "basic" (\_ -> "hello/toi.csv" |> Regex.replace "[/.]" "-" |> Expect.equal "hello-toi-csv")
            ]
        , describe "countI"
            [ test "basic" (\_ -> "a b c d a b a" |> Regex.countI "a" |> Expect.equal 3)
            ]
        ]
