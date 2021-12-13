module Libs.Models.ColorTest exposing (..)

import Expect
import Libs.Models.Color exposing (RgbColor, green, hex, hexToRgb, rgba)
import Libs.Models.TwColor exposing (TwColorLevel(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Color"
        [ describe "rgba"
            [ test "green" (\_ -> green |> rgba "0" L500 |> Expect.equal "rgba(34, 197, 94, 0)")
            ]
        , describe "hex"
            [ test "green" (\_ -> green |> hex L500 |> Expect.equal "#22c55e")
            ]
        , describe "hexToRgb"
            [ test "white" (\_ -> "#ffffff" |> hexToRgb |> Expect.equal (Just (RgbColor 255 255 255)))
            , test "black" (\_ -> "#000000" |> hexToRgb |> Expect.equal (Just (RgbColor 0 0 0)))
            , test "green" (\_ -> "#22c55e" |> hexToRgb |> Expect.equal (Just (RgbColor 34 197 94)))
            , test "bad" (\_ -> "not a color" |> hexToRgb |> Expect.equal Nothing)
            ]
        ]
