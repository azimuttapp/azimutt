module Libs.StringCaseTest exposing (..)

import Expect
import Libs.StringCase exposing (StringCase(..), compatibleCases, isCamelLower, isCamelUpper, isKebab, isSnakeLower, isSnakeUpper)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "StringCase"
        [ describe "CamelUpper"
            [ test "valid" (\_ -> "AzimuttIsAwesome" |> isCamelUpper |> Expect.equal True)
            , test "bad lower" (\_ -> "azimuttIsAwesome" |> isCamelUpper |> Expect.equal False)
            , test "bad underscore" (\_ -> "azimutt_is_awesome" |> isCamelUpper |> Expect.equal False)
            ]
        , describe "CamelLower"
            [ test "valid" (\_ -> "azimuttIsAwesome" |> isCamelLower |> Expect.equal True)
            , test "bad upper" (\_ -> "AzimuttIsAwesome" |> isCamelLower |> Expect.equal False)
            , test "bad underscore" (\_ -> "azimutt_is_awesome" |> isCamelLower |> Expect.equal False)
            ]
        , describe "SnakeUpper"
            [ test "valid" (\_ -> "AZIMUTT_IS_AWESOME" |> isSnakeUpper |> Expect.equal True)
            , test "bad lower" (\_ -> "azimutt_is_awesome" |> isSnakeUpper |> Expect.equal False)
            ]
        , describe "SnakeLower"
            [ test "valid" (\_ -> "azimutt_is_awesome" |> isSnakeLower |> Expect.equal True)
            , test "bad upper" (\_ -> "AZIMUTT_IS_AWESOME" |> isSnakeLower |> Expect.equal False)
            ]
        , describe "Kebab"
            [ test "valid" (\_ -> "azimutt-is-awesome" |> isKebab |> Expect.equal True)
            , test "bad upper" (\_ -> "AZIMUTT-IS-AWESOME" |> isKebab |> Expect.equal False)
            , test "bad underscore" (\_ -> "azimutt_is_awesome" |> isKebab |> Expect.equal False)
            ]
        , describe "compatibleCases"
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
