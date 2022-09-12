module Libs.Models.AreaTest exposing (..)

import Expect
import Libs.Models.Area exposing (Area, overlap)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Models.Area"
        [ describe "overlap"
            [ test "distinct" (\_ -> Area Position.zero (Size 10 10) |> overlap (Area (Position 20 20) (Size 30 30)) |> Expect.equal False)
            , test "inside" (\_ -> Area Position.zero (Size 10 10) |> overlap (Area (Position 5 5) (Size 30 30)) |> Expect.equal True)
            , test "cross" (\_ -> Area Position.zero (Size 10 10) |> overlap (Area (Position -5 5) (Size 15 7)) |> Expect.equal True)
            ]
        ]
