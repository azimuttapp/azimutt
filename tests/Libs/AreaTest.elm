module Libs.AreaTest exposing (..)

import Expect
import Libs.Area exposing (Area, mult, overlap)
import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Area"
        [ describe "mult"
            [ test "no change" (\_ -> Area (Position 0 0) (Size 50 50) |> mult 1 |> Expect.equal (Area (Position 0 0) (Size 50 50)))
            , test "double" (\_ -> Area (Position 0 0) (Size 50 50) |> mult 2 |> Expect.equal (Area (Position 0 0) (Size 100 100)))
            ]
        , describe "overlap"
            [ test "distinct" (\_ -> Area (Position 0 0) (Size 10 10) |> overlap (Area (Position 20 20) (Size 30 30)) |> Expect.equal False)
            , test "inside" (\_ -> Area (Position 0 0) (Size 10 10) |> overlap (Area (Position 5 5) (Size 30 30)) |> Expect.equal True)
            , test "cross" (\_ -> Area (Position 0 0) (Size 10 10) |> overlap (Area (Position -5 5) (Size 15 7)) |> Expect.equal True)
            ]
        ]
