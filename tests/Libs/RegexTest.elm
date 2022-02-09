module Libs.RegexTest exposing (..)

import Expect
import Libs.Regex as Regex
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Regex"
        [ describe "contains"
            [ test "basic" (\_ -> "a END)" |> Regex.contains "[^A-Z]END[^A-Z]" |> Expect.equal True)
            , test "basic 2" (\_ -> "a ENDe" |> Regex.contains "[^A-Z]END[^A-Z]" |> Expect.equal False)
            ]
        , describe "replace"
            [ test "basic" (\_ -> "hello/toi.csv" |> Regex.replace "[/.]" "-" |> Expect.equal "hello-toi-csv")
            ]
        ]
