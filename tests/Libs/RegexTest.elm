module Libs.RegexTest exposing (..)

import Expect
import Libs.Regex as R
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Regex"
        [ describe "contains"
            [ test "basic" (\_ -> "a END)" |> R.contains "[^A-Z]END[^A-Z]" |> Expect.equal True)
            , test "basic 2" (\_ -> "a ENDe" |> R.contains "[^A-Z]END[^A-Z]" |> Expect.equal False)
            ]
        ]
