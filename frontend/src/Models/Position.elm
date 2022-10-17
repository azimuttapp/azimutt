module Models.Position exposing (Canvas, CanvasGrid, Diagram, Document, Viewport, buildCanvas, buildCanvasGrid, buildDiagram, buildViewport, canvasToViewport, decodeCanvasGrid, decodeDiagram, decodeDocument, decodeViewport, diagramToCanvas, diffCanvas, diffViewport, divCanvas, encodeCanvasGrid, encodeDiagram, extractCanvas, extractCanvasGrid, extractViewport, fromEventViewport, minCanvas, moveCanvas, moveCanvasGrid, moveDiagram, moveViewport, offGrid, onGrid, roundDiagram, sizeCanvas, styleTransformCanvas, styleTransformDiagram, stylesCanvasGrid, stylesViewport, toStringRoundDiagram, toStringRoundViewport, viewportToCanvas, zeroCanvas, zeroCanvasGrid, zeroDiagram, zeroViewport)

import Html exposing (Attribute)
import Html.Attributes exposing (style)
import Html.Events.Extra.Mouse exposing (Event)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode
import Libs.Models.Delta exposing (Delta)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Size as Size


type Viewport
    = Viewport Position -- position in the browser viewport (for the erd, mouse...)


type Document
    = Document Position -- position in the html document (same as Viewport if no scroll)


type Diagram
    = Diagram Position -- position in the erd (for the canvas)


type Canvas
    = Canvas Position -- position in the canvas (for tables, relations...)


type CanvasGrid
    = CanvasGrid Position -- same as Canvas but with a grid step


gridStep : Int
gridStep =
    10


alignCoord : Float -> Float
alignCoord value =
    value |> round |> (\v -> (v - modBy gridStep v) |> toFloat)


alignPos : Position -> Position
alignPos pos =
    Position (alignCoord pos.left) (alignCoord pos.top)


buildDocument : Position -> Document
buildDocument pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> Document


buildViewport : Position -> Viewport
buildViewport pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> Viewport


extractViewport : Viewport -> Position
extractViewport (Viewport pos) =
    -- use it only in last resort in very narrow and explicit scope
    pos


buildDiagram : Position -> Diagram
buildDiagram pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> Diagram


buildCanvas : Position -> Canvas
buildCanvas pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> Canvas


extractCanvas : Canvas -> Position
extractCanvas (Canvas pos) =
    -- use it only in last resort in very narrow and explicit scope
    pos


buildCanvasGrid : Position -> CanvasGrid
buildCanvasGrid pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> alignPos |> CanvasGrid


extractCanvasGrid : CanvasGrid -> Position
extractCanvasGrid (CanvasGrid pos) =
    -- use it only in last resort in very narrow and explicit scope
    pos


zeroViewport : Viewport
zeroViewport =
    Viewport Position.zero


zeroDiagram : Diagram
zeroDiagram =
    Diagram Position.zero


zeroCanvas : Canvas
zeroCanvas =
    Canvas Position.zero


zeroCanvasGrid : CanvasGrid
zeroCanvasGrid =
    CanvasGrid Position.zero


fromEventViewport : Event -> Viewport
fromEventViewport e =
    e.clientPos |> (\( l, t ) -> Position l t) |> buildViewport


moveViewport : Delta -> Viewport -> Viewport
moveViewport delta (Viewport pos) =
    pos |> Position.move delta |> buildViewport


moveDiagram : Delta -> Diagram -> Diagram
moveDiagram delta (Diagram pos) =
    pos |> Position.move delta |> buildDiagram


moveCanvas : Delta -> Canvas -> Canvas
moveCanvas delta (Canvas pos) =
    pos |> Position.move delta |> buildCanvas


moveCanvasGrid : Delta -> CanvasGrid -> CanvasGrid
moveCanvasGrid delta (CanvasGrid pos) =
    pos |> Position.move delta |> buildCanvasGrid


minCanvas : Canvas -> Canvas -> Canvas
minCanvas (Canvas p1) (Canvas p2) =
    Position.min p1 p2 |> buildCanvas


sizeCanvas : Canvas -> Canvas -> Size.Canvas
sizeCanvas (Canvas p1) (Canvas p2) =
    Position.size p1 p2 |> Size.buildCanvas


divCanvas : Float -> Canvas -> Canvas
divCanvas factor (Canvas pos) =
    Position.div factor pos |> buildCanvas


diffViewport : Viewport -> Viewport -> Delta
diffViewport (Viewport to) (Viewport from) =
    from |> Position.diff to


diffCanvas : Canvas -> Canvas -> Delta
diffCanvas (Canvas to) (Canvas from) =
    from |> Position.diff to


roundDiagram : Diagram -> Diagram
roundDiagram (Diagram pos) =
    pos |> Position.round |> buildDiagram


onGrid : Canvas -> CanvasGrid
onGrid (Canvas pos) =
    buildCanvasGrid pos


offGrid : CanvasGrid -> Canvas
offGrid (CanvasGrid pos) =
    buildCanvas pos


viewportToCanvas : Viewport -> Diagram -> ZoomLevel -> Viewport -> Canvas
viewportToCanvas (Viewport erdPos) (Diagram canvasPos) canvasZoom (Viewport pos) =
    pos
        |> Position.move (Position.zero |> Position.diff erdPos)
        |> Position.move (Position.zero |> Position.diff canvasPos)
        |> Position.div canvasZoom
        |> buildCanvas


canvasToViewport : Viewport -> Diagram -> ZoomLevel -> Canvas -> Viewport
canvasToViewport (Viewport erdPos) (Diagram canvasPos) canvasZoom (Canvas pos) =
    pos
        |> Position.mult canvasZoom
        |> Position.move (canvasPos |> Position.diff Position.zero)
        |> Position.move (erdPos |> Position.diff Position.zero)
        |> buildViewport


diagramToCanvas : Diagram -> Diagram -> Canvas
diagramToCanvas (Diagram canvasPos) (Diagram pos) =
    pos
        |> Position.move (Position.zero |> Position.diff canvasPos)
        |> buildCanvas


stylesViewport : Viewport -> List (Attribute msg)
stylesViewport (Viewport pos) =
    [ style "left" (String.fromFloat pos.left ++ "px"), style "top" (String.fromFloat pos.top ++ "px") ]


styleTransformDiagram : Diagram -> ZoomLevel -> Attribute msg
styleTransformDiagram (Diagram pos) zoom =
    style "transform" ("translate(" ++ String.fromFloat pos.left ++ "px, " ++ String.fromFloat pos.top ++ "px) scale(" ++ String.fromFloat zoom ++ ")")


styleTransformCanvas : Canvas -> Attribute msg
styleTransformCanvas (Canvas pos) =
    style "transform" ("translate(" ++ String.fromFloat pos.left ++ "px, " ++ String.fromFloat pos.top ++ "px)")


stylesCanvasGrid : CanvasGrid -> List (Attribute msg)
stylesCanvasGrid (CanvasGrid pos) =
    [ style "left" (String.fromFloat pos.left ++ "px"), style "top" (String.fromFloat pos.top ++ "px") ]


toStringRoundViewport : Viewport -> String
toStringRoundViewport (Viewport pos) =
    Position.toStringRound pos


toStringRoundDiagram : Diagram -> String
toStringRoundDiagram (Diagram pos) =
    Position.toStringRound pos


decodeViewport : Decode.Decoder Viewport
decodeViewport =
    Decode.map2 (\x y -> Position x y |> buildViewport)
        (Decode.field "clientX" Decode.float)
        (Decode.field "clientY" Decode.float)


decodeDocument : Decode.Decoder Document
decodeDocument =
    Decode.map2 (\x y -> Position x y |> buildDocument)
        (Decode.field "pageX" Decode.float)
        (Decode.field "pageY" Decode.float)


encodeDiagram : Diagram -> Value
encodeDiagram (Diagram pos) =
    Encode.notNullObject
        [ ( "left", pos.left |> Encode.float )
        , ( "top", pos.top |> Encode.float )
        ]


decodeDiagram : Decode.Decoder Diagram
decodeDiagram =
    Decode.map2 (\l t -> Position l t |> buildDiagram)
        (Decode.field "left" Decode.float)
        (Decode.field "top" Decode.float)


encodeCanvasGrid : CanvasGrid -> Value
encodeCanvasGrid (CanvasGrid pos) =
    Encode.notNullObject
        [ ( "left", pos.left |> alignCoord |> Encode.float )
        , ( "top", pos.top |> alignCoord |> Encode.float )
        ]


decodeCanvasGrid : Decode.Decoder CanvasGrid
decodeCanvasGrid =
    Decode.map2 (\l t -> Position l t |> buildCanvasGrid)
        (Decode.field "left" Decode.float)
        (Decode.field "top" Decode.float)
