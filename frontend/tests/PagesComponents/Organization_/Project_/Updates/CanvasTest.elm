module PagesComponents.Organization_.Project_.Updates.CanvasTest exposing (..)

import Expect
import Fuzz exposing (tuple)
import Libs.Models.Delta as Delta exposing (Delta)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Models.Area as Area
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Updates.Canvas exposing (computeFit, performZoom)
import Services.Lenses exposing (mapPosition)
import Test exposing (Test, describe, fuzz, test)
import TestHelpers.Fuzzers exposing (positionViewport)
import TestHelpers.ProjectFuzzers exposing (canvasProps)


suite : Test
suite =
    describe "PagesComponents.Organization_.Project_.Updates.Canvas"
        [ describe "performZoom"
            [ test "basic" (\_ -> CanvasProps (canvasPos 0 0) 1 |> performZoom erdElem 0.5 (viewportPos 50 50) |> Expect.equal (CanvasProps (canvasPos -25 -25) 1.5))
            , test "basic round trip" (\_ -> CanvasProps (canvasPos 0 0) 1 |> performZoom erdElem 0.5 (viewportPos 50 50) |> performZoom erdElem -0.5 (viewportPos 50 50) |> Expect.equal (CanvasProps (canvasPos 0 0) 1))
            , test "complex" (\_ -> CanvasProps (canvasPos 50 20) 0.5 |> performZoom erdElem 0.1 (viewportPos 200 300) |> Expect.equal (CanvasProps (canvasPos 20 -36) 0.6))
            , fuzz (tuple ( positionViewport, canvasProps )) "no change" (\( pos, props ) -> props |> performZoom erdElem 0 pos |> Expect.equal (props |> mapPosition Position.roundDiagram))

            --, fuzz (tuple3 ( float, positionViewport, canvasProps )) "round trip" (\( delta, pos, props ) -> props |> performZoom erdElem delta pos |> performZoom erdElem -delta pos |> Expect.equal (props |> mapPosition Position.roundCanvas))
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


erdElem : ErdProps
erdElem =
    { position = Position 0 0 |> Position.viewport, size = Size 0 0 |> Size.viewport }


inArea : Position -> Size -> Area.Canvas
inArea pos size =
    Area.Canvas (Position.canvas pos) (Size.canvas size)


viewportPos : Float -> Float -> Position.Viewport
viewportPos x y =
    Position x y |> Position.viewport


canvasPos : Float -> Float -> Position.Diagram
canvasPos x y =
    Position x y |> Position.diagram
