module PagesComponents.App.Updates.CanvasTest exposing (..)

import Expect exposing (Expectation, FloatingPointTolerance(..))
import Fuzz exposing (tuple)
import Libs.Area exposing (Area)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Models.Project.CanvasProps exposing (CanvasProps)
import PagesComponents.App.Updates.Canvas exposing (computeFit, performZoom)
import Test exposing (Test, describe, fuzz, test)
import TestHelpers.Fuzzers exposing (position)
import TestHelpers.ProjectFuzzers exposing (canvasProps)


suite : Test
suite =
    describe "PagesComponents.App.Updates.Canvas"
        [ describe "performZoom"
            [ fuzz (tuple ( position, canvasProps )) "no change" (\( pos, props ) -> props |> performZoom 0 pos |> Expect.equal props)

            -- , fuzz (tuple3 ( float, position, canvasProps )) "round trip" (\( delta, pos, props ) -> props |> performZoom delta pos |> performZoom -delta pos |> expectAlmost props)
            , test "basic" (\_ -> CanvasProps Position.zero Size.zero Position.zero 1 |> performZoom 0.5 (Position 50 50) |> Expect.equal (CanvasProps Position.zero Size.zero (Position -25 -25) 1.5))
            , test "basic round trip" (\_ -> CanvasProps Position.zero Size.zero Position.zero 1 |> performZoom 0.5 (Position 50 50) |> performZoom -0.5 (Position 50 50) |> expectAlmost (CanvasProps Position.zero Size.zero Position.zero 1))
            ]
        , describe "computeFit"
            [ test "no change" (\_ -> computeFit (Area Position.zero (Size 50 50)) 0 (Area Position.zero (Size 50 50)) 1 |> Expect.equal ( 1, Position.zero ))
            , test "no change with padding" (\_ -> computeFit (Area Position.zero (Size 70 70)) 10 (Area (Position 10 10) (Size 50 50)) 1 |> Expect.equal ( 1, Position.zero ))
            , test "no change with vertical space" (\_ -> computeFit (Area Position.zero (Size 50 70)) 0 (Area Position.zero (Size 50 50)) 1 |> Expect.equal ( 1, Position 0 10 ))
            , test "no change with horizontal space" (\_ -> computeFit (Area Position.zero (Size 70 50)) 0 (Area Position.zero (Size 50 50)) 1 |> Expect.equal ( 1, Position 10 0 ))
            , test "grow" (\_ -> computeFit (Area Position.zero (Size 100 100)) 0 (Area Position.zero (Size 50 50)) 0.5 |> Expect.equal ( 1, Position.zero ))

            -- , test "complex" (\_ -> computeFit (Area 315 25 863 412) 10 (Area 23 42 465 386) 1.5 |> Expect.equal ( 1.6293604651162794, Position 8.246208742194483 -35.8626226583408 ))
            ]
        ]


expectAlmost : CanvasProps -> CanvasProps -> Expectation
expectAlmost expected props =
    props
        |> Expect.all
            [ \p -> p.zoom |> Expect.within (AbsoluteOrRelative 0.0001 0.0001) expected.zoom
            , \p -> p.position.left |> Expect.within (AbsoluteOrRelative 0.0001 0.0001) expected.position.left
            , \p -> p.position.top |> Expect.within (AbsoluteOrRelative 0.0001 0.0001) expected.position.top
            ]
