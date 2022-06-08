module Libs.StringCaseTest exposing (..)

import Expect
import Libs.StringCase exposing (StringCase(..), compatibleCases)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "StringCase"
        [ describe "compatibleCases"
            [ test "CamelUpper" (\_ -> "AzimuttIsAwesome" |> compatibleCases |> Expect.equal [ CamelUpper ])
            , test "CamelLower" (\_ -> "azimuttIsAwesome" |> compatibleCases |> Expect.equal [ CamelLower ])
            , test "SnakeUpper" (\_ -> "AZIMUTT_IS_AWESOME" |> compatibleCases |> Expect.equal [ SnakeUpper ])
            , test "SnakeLower" (\_ -> "azimutt_is_awesome" |> compatibleCases |> Expect.equal [ SnakeLower ])
            , test "Kebab" (\_ -> "azimutt-is-awesome" |> compatibleCases |> Expect.equal [ Kebab ])
            , test "AZ" (\_ -> "AZ" |> compatibleCases |> Expect.equal [ CamelUpper, SnakeUpper ])
            , test "az" (\_ -> "az" |> compatibleCases |> Expect.equal [ CamelLower, SnakeLower, Kebab ])
            , test "text" (\_ -> "some text" |> compatibleCases |> Expect.equal [])
            ]
        ]
