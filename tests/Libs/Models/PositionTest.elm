module Libs.Models.PositionTest exposing (..)

import Expect
import Libs.Models.Position as Position
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Position"
        [ describe "stepBy"
            [ test "int" (\_ -> { left = 123, top = 321 } |> Position.stepBy 10 |> Expect.equal { left = 120, top = 320 })
            , test "float" (\_ -> { left = 123.12, top = 321.42 } |> Position.stepBy 10 |> Expect.equal { left = 120, top = 320 })
            ]
        ]
