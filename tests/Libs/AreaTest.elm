module Libs.AreaTest exposing (..)

import Expect
import Libs.Area exposing (Area, overlap, scale)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Area"
        [ describe "scale"
            [ test "no change" (\_ -> Area 0 0 50 50 |> scale 1 |> Expect.equal (Area 0 0 50 50))
            , test "double" (\_ -> Area 0 0 50 50 |> scale 2 |> Expect.equal (Area 0 0 100 100))
            ]
        , describe "overlap"
            [ test "distinct" (\_ -> Area 0 0 10 10 |> overlap (Area 20 20 30 30) |> Expect.equal False)
            , test "inside" (\_ -> Area 0 0 10 10 |> overlap (Area 5 5 30 30) |> Expect.equal True)
            , test "cross" (\_ -> Area 0 0 10 10 |> overlap (Area -5 5 15 7) |> Expect.equal True)
            ]
        ]
