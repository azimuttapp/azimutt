module Libs.AreaTest exposing (..)

import Expect
import Libs.Area exposing (Area, scale)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Area"
        [ describe "scale"
            [ test "no change" (\_ -> Area 0 0 50 50 |> scale 1 |> Expect.equal (Area 0 0 50 50))
            , test "double" (\_ -> Area 0 0 50 50 |> scale 2 |> Expect.equal (Area 0 0 100 100))
            ]
        ]
