module PagesComponents.Projects.Id_.Updates.CanvasTest exposing (..)

import Expect exposing (Expectation, FloatingPointTolerance(..))
import Fuzz exposing (tuple)
import Libs.Delta as Delta exposing (Delta)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Models.Area as Area
import Models.Position as Position
import Models.Project.CanvasProps exposing (CanvasProps)
import PagesComponents.Projects.Id_.Updates.Canvas exposing (computeFit, performZoom, performZoom2)
import Test exposing (Test, describe, fuzz, test)
import TestHelpers.Fuzzers exposing (positionInCanvas)
import TestHelpers.ProjectFuzzers exposing (canvasProps)


suite : Test
suite =
    describe "PagesComponents.Projects.Id_.Updates.Canvas"
        [ describe "performZoom"
            [ fuzz (tuple ( positionInCanvas, canvasProps )) "no change" (\( pos, props ) -> props |> performZoom 0 pos |> Expect.equal props)

            -- , fuzz (tuple3 ( float, position, canvasProps )) "round trip" (\( delta, pos, props ) -> props |> performZoom delta pos |> performZoom -delta pos |> expectAlmost props)
            , test "basic" (\_ -> CanvasProps (canvasPos 0 0) 1 |> performZoom 0.5 (inCanvasPos 50 50) |> Expect.equal (CanvasProps (canvasPos -25 -25) 1.5))
            , test "basic round trip" (\_ -> CanvasProps (canvasPos 0 0) 1 |> performZoom 0.5 (inCanvasPos 50 50) |> performZoom -0.5 (inCanvasPos 50 50) |> expectAlmost (CanvasProps (canvasPos 0 0) 1))
            ]
        , describe "computeFit"
            [ test "no change" (\_ -> computeFit (inArea Position.zero (Size 50 50)) 0 (inArea Position.zero (Size 50 50)) 1 |> Expect.equal ( 1, Delta.zero ))
            , test "no change with padding" (\_ -> computeFit (inArea Position.zero (Size 70 70)) 10 (inArea (Position 10 10) (Size 50 50)) 1 |> Expect.equal ( 1, Delta.zero ))
            , test "no change with vertical space" (\_ -> computeFit (inArea Position.zero (Size 50 70)) 0 (inArea Position.zero (Size 50 50)) 1 |> Expect.equal ( 1, Delta 0 10 ))
            , test "no change with horizontal space" (\_ -> computeFit (inArea Position.zero (Size 70 50)) 0 (inArea Position.zero (Size 50 50)) 1 |> Expect.equal ( 1, Delta 10 0 ))
            , test "grow" (\_ -> computeFit (inArea Position.zero (Size 100 100)) 0 (inArea Position.zero (Size 50 50)) 0.5 |> Expect.equal ( 1, Delta.zero ))

            -- , test "complex" (\_ -> computeFit (Area 315 25 863 412) 10 (Area 23 42 465 386) 1.5 |> Expect.equal ( 1.6293604651162794, Position 8.246208742194483 -35.8626226583408 ))
            ]
        ]


inArea : Position -> Size -> Area.InCanvas
inArea pos size =
    Area.InCanvas (Position.buildInCanvas pos) size


canvasPos : Float -> Float -> Position.Canvas
canvasPos x y =
    Position x y |> Position.buildCanvas


inCanvasPos : Float -> Float -> Position.InCanvas
inCanvasPos x y =
    Position x y |> Position.buildInCanvas


expectAlmost : CanvasProps -> CanvasProps -> Expectation
expectAlmost expected props =
    let
        expectedPos : Position
        expectedPos =
            expected.position |> Position.extractCanvas
    in
    props
        |> Expect.all
            [ .zoom >> Expect.within (AbsoluteOrRelative 0.0001 0.0001) expected.zoom
            , .position >> Position.extractCanvas >> .left >> Expect.within (AbsoluteOrRelative 0.0001 0.0001) expectedPos.left
            , .position >> Position.extractCanvas >> .top >> Expect.within (AbsoluteOrRelative 0.0001 0.0001) expectedPos.top
            ]
