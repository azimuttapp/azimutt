module Libs.Models.PositionTest exposing (..)

import Expect
import Libs.Models.Position as Position
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Position"
        [ describe "min"
            [ test "case 1" (\_ -> { left = 0, top = 0 } |> Position.min { left = 10, top = 10 } |> Expect.equal { left = 0, top = 0 })
            , test "case 2" (\_ -> { left = 10, top = 0 } |> Position.min { left = 0, top = 10 } |> Expect.equal { left = 0, top = 0 })
            , test "case 3" (\_ -> { left = 0, top = 10 } |> Position.min { left = 10, top = 0 } |> Expect.equal { left = 0, top = 0 })
            , test "case 4" (\_ -> { left = 10, top = 10 } |> Position.min { left = 0, top = 0 } |> Expect.equal { left = 0, top = 0 })
            ]
        , describe "size"
            [ test "basic" (\_ -> { left = 0, top = 0 } |> Position.size { left = 10, top = 10 } |> Expect.equal { width = 10, height = 10 }) ]
        , describe "diff"
            [ test "basic" (\_ -> { left = 0, top = 0 } |> Position.diff { left = 10, top = 10 } |> Expect.equal { dx = -10, dy = -10 }) ]
        ]
