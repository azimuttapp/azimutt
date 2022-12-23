module Models.Position exposing (Canvas, CanvasGrid, Diagram, Document, Viewport, canvas, canvasToViewport, decodeDiagram, decodeDocument, decodeGrid, decodeViewport, diagram, diagramToCanvas, diffCanvas, diffViewport, divCanvas, encodeDiagram, encodeGrid, extractCanvas, extractGrid, extractViewport, fromEventViewport, grid, minCanvas, moveCanvas, moveDiagram, moveGrid, moveViewport, negateGrid, offGrid, onGrid, roundDiagram, sizeCanvas, styleTransformCanvas, styleTransformDiagram, stylesGrid, stylesViewport, toStringRoundDiagram, toStringRoundViewport, viewport, viewportToCanvas, zeroCanvas, zeroDiagram, zeroGrid, zeroViewport)

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


document : Position -> Document
document pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> Document


viewport : Position -> Viewport
viewport pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> Viewport


extractViewport : Viewport -> Position
extractViewport (Viewport pos) =
    -- use it only in last resort in very narrow and explicit scope
    pos


diagram : Position -> Diagram
diagram pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> Diagram


canvas : Position -> Canvas
canvas pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> Canvas


extractCanvas : Canvas -> Position
extractCanvas (Canvas pos) =
    -- use it only in last resort in very narrow and explicit scope
    pos


grid : Position -> CanvasGrid
grid pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> alignPos |> CanvasGrid


extractGrid : CanvasGrid -> Position
extractGrid (CanvasGrid pos) =
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


zeroGrid : CanvasGrid
zeroGrid =
    CanvasGrid Position.zero


fromEventViewport : Event -> Viewport
fromEventViewport e =
    e.clientPos |> (\( l, t ) -> Position l t) |> viewport


moveViewport : Delta -> Viewport -> Viewport
moveViewport delta (Viewport pos) =
    pos |> Position.move delta |> viewport


moveDiagram : Delta -> Diagram -> Diagram
moveDiagram delta (Diagram pos) =
    pos |> Position.move delta |> diagram


moveCanvas : Delta -> Canvas -> Canvas
moveCanvas delta (Canvas pos) =
    pos |> Position.move delta |> canvas


moveGrid : Delta -> CanvasGrid -> CanvasGrid
moveGrid delta (CanvasGrid pos) =
    pos |> Position.move delta |> grid


negateGrid : CanvasGrid -> CanvasGrid
negateGrid (CanvasGrid pos) =
    Position.negate pos |> CanvasGrid


minCanvas : Canvas -> Canvas -> Canvas
minCanvas (Canvas p1) (Canvas p2) =
    Position.min p1 p2 |> canvas


sizeCanvas : Canvas -> Canvas -> Size.Canvas
sizeCanvas (Canvas p1) (Canvas p2) =
    Position.size p1 p2 |> Size.canvas


divCanvas : Float -> Canvas -> Canvas
divCanvas factor (Canvas pos) =
    Position.div factor pos |> canvas


diffViewport : Viewport -> Viewport -> Delta
diffViewport (Viewport to) (Viewport from) =
    from |> Position.diff to


diffCanvas : Canvas -> Canvas -> Delta
diffCanvas (Canvas to) (Canvas from) =
    from |> Position.diff to


roundDiagram : Diagram -> Diagram
roundDiagram (Diagram pos) =
    pos |> Position.round |> diagram


onGrid : Canvas -> CanvasGrid
onGrid (Canvas pos) =
    grid pos


offGrid : CanvasGrid -> Canvas
offGrid (CanvasGrid pos) =
    canvas pos


viewportToCanvas : Viewport -> Diagram -> ZoomLevel -> Viewport -> Canvas
viewportToCanvas (Viewport erdPos) (Diagram canvasPos) canvasZoom (Viewport pos) =
    pos
        |> Position.move (Position.zero |> Position.diff erdPos)
        |> Position.move (Position.zero |> Position.diff canvasPos)
        |> Position.div canvasZoom
        |> canvas


canvasToViewport : Viewport -> Diagram -> ZoomLevel -> Canvas -> Viewport
canvasToViewport (Viewport erdPos) (Diagram canvasPos) canvasZoom (Canvas pos) =
    pos
        |> Position.mult canvasZoom
        |> Position.move (canvasPos |> Position.diff Position.zero)
        |> Position.move (erdPos |> Position.diff Position.zero)
        |> viewport


diagramToCanvas : Diagram -> Diagram -> Canvas
diagramToCanvas (Diagram canvasPos) (Diagram pos) =
    pos
        |> Position.move (Position.zero |> Position.diff canvasPos)
        |> canvas


stylesViewport : Viewport -> List (Attribute msg)
stylesViewport (Viewport pos) =
    [ style "left" (String.fromFloat pos.left ++ "px"), style "top" (String.fromFloat pos.top ++ "px") ]


styleTransformDiagram : Diagram -> ZoomLevel -> Attribute msg
styleTransformDiagram (Diagram pos) zoom =
    style "transform" ("translate(" ++ String.fromFloat pos.left ++ "px, " ++ String.fromFloat pos.top ++ "px) scale(" ++ String.fromFloat zoom ++ ")")


styleTransformCanvas : Canvas -> Attribute msg
styleTransformCanvas (Canvas pos) =
    style "transform" ("translate(" ++ String.fromFloat pos.left ++ "px, " ++ String.fromFloat pos.top ++ "px)")


stylesGrid : CanvasGrid -> List (Attribute msg)
stylesGrid (CanvasGrid pos) =
    [ style "left" (String.fromFloat pos.left ++ "px"), style "top" (String.fromFloat pos.top ++ "px") ]


toStringRoundViewport : Viewport -> String
toStringRoundViewport (Viewport pos) =
    Position.toStringRound pos


toStringRoundDiagram : Diagram -> String
toStringRoundDiagram (Diagram pos) =
    Position.toStringRound pos


decodeViewport : Decode.Decoder Viewport
decodeViewport =
    Decode.map2 (\x y -> Position x y |> viewport)
        (Decode.field "clientX" Decode.float)
        (Decode.field "clientY" Decode.float)


decodeDocument : Decode.Decoder Document
decodeDocument =
    Decode.map2 (\x y -> Position x y |> document)
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
    Decode.map2 (\l t -> Position l t |> diagram)
        (Decode.field "left" Decode.float)
        (Decode.field "top" Decode.float)


encodeGrid : CanvasGrid -> Value
encodeGrid (CanvasGrid pos) =
    Encode.notNullObject
        [ ( "left", pos.left |> alignCoord |> Encode.float )
        , ( "top", pos.top |> alignCoord |> Encode.float )
        ]


decodeGrid : Decode.Decoder CanvasGrid
decodeGrid =
    Decode.map2 (\l t -> Position l t |> grid)
        (Decode.field "left" Decode.float)
        (Decode.field "top" Decode.float)
