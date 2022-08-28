module Models.Position exposing (Canvas, Document, Grid, InCanvas, Viewport, buildCanvas, buildGrid, buildInCanvas, buildViewport, canvasToInCanvas, decodeCanvas, decodeDocument, decodeGrid, decodeViewport, diffInCanvas, diffViewport, divInCanvas, encodeCanvas, encodeGrid, extractCanvas, extractGrid, extractInCanvas, extractViewport, fromEventViewport, inCanvasToViewport, minInCanvas, moveCanvas, moveGrid, moveInCanvas, moveViewport, offGrid, onGrid, roundCanvas, sizeInCanvas, styleCanvas, stylesGrid, stylesTransformInCanvas, stylesViewport, subInCanvas, toStringRoundCanvas, toStringRoundViewport, viewportToInCanvas, zeroCanvas, zeroGrid, zeroInCanvas, zeroViewport)

import Html exposing (Attribute)
import Html.Attributes exposing (style)
import Html.Events.Extra.Mouse exposing (Event)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Delta exposing (Delta)
import Libs.Json.Encode as Encode
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Libs.Models.ZoomLevel exposing (ZoomLevel)


type Viewport
    = Viewport Position -- position in the browser viewport (for the erd, mouse...)


type Document
    = Document Position -- position in the html document (same as Viewport if no scroll)


type Canvas
    = Canvas Position -- position in the erd (for the canvas)


type InCanvas
    = InCanvas Position -- position in the canvas (for tables, relations...)


type Grid
    = Grid Position -- same as InCanvas but with a grid step


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


buildCanvas : Position -> Canvas
buildCanvas pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> Canvas


extractCanvas : Canvas -> Position
extractCanvas (Canvas pos) =
    -- use it only in last resort in very narrow and explicit scope
    pos


buildInCanvas : Position -> InCanvas
buildInCanvas pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> InCanvas


extractInCanvas : InCanvas -> Position
extractInCanvas (InCanvas pos) =
    -- use it only in last resort in very narrow and explicit scope
    pos


buildGrid : Position -> Grid
buildGrid pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> alignPos |> Grid


extractGrid : Grid -> Position
extractGrid (Grid pos) =
    -- use it only in last resort in very narrow and explicit scope
    pos


zeroViewport : Viewport
zeroViewport =
    Viewport Position.zero


zeroCanvas : Canvas
zeroCanvas =
    Canvas Position.zero


zeroInCanvas : InCanvas
zeroInCanvas =
    InCanvas Position.zero


zeroGrid : Grid
zeroGrid =
    Grid Position.zero


fromEventViewport : Event -> Viewport
fromEventViewport e =
    e.clientPos |> (\( l, t ) -> Position l t) |> buildViewport


moveViewport : Delta -> Viewport -> Viewport
moveViewport delta (Viewport pos) =
    pos |> Position.move delta |> buildViewport


moveCanvas : Delta -> Canvas -> Canvas
moveCanvas delta (Canvas pos) =
    pos |> Position.move delta |> buildCanvas


moveInCanvas : Delta -> InCanvas -> InCanvas
moveInCanvas delta (InCanvas pos) =
    pos |> Position.move delta |> buildInCanvas


moveGrid : Delta -> Grid -> Grid
moveGrid delta (Grid pos) =
    pos |> Position.move delta |> buildGrid


subInCanvas : InCanvas -> InCanvas -> InCanvas
subInCanvas (InCanvas delta) (InCanvas pos) =
    Position.sub delta pos |> buildInCanvas


minInCanvas : InCanvas -> InCanvas -> InCanvas
minInCanvas (InCanvas p1) (InCanvas p2) =
    Position.min p1 p2 |> buildInCanvas


sizeInCanvas : InCanvas -> InCanvas -> Size
sizeInCanvas (InCanvas p1) (InCanvas p2) =
    Position.size p1 p2


divInCanvas : Float -> InCanvas -> InCanvas
divInCanvas factor (InCanvas pos) =
    Position.div factor pos |> buildInCanvas


diffViewport : Viewport -> Viewport -> Delta
diffViewport (Viewport to) (Viewport from) =
    from |> Position.diff to


diffInCanvas : InCanvas -> InCanvas -> Delta
diffInCanvas (InCanvas to) (InCanvas from) =
    from |> Position.diff to


roundCanvas : Canvas -> Canvas
roundCanvas (Canvas pos) =
    pos |> Position.round |> buildCanvas


onGrid : InCanvas -> Grid
onGrid (InCanvas pos) =
    buildGrid pos


offGrid : Grid -> InCanvas
offGrid (Grid pos) =
    buildInCanvas pos


viewportToInCanvas : Viewport -> Canvas -> ZoomLevel -> Viewport -> InCanvas
viewportToInCanvas (Viewport erdPos) (Canvas canvasPos) canvasZoom (Viewport pos) =
    pos |> Position.sub erdPos |> Position.sub canvasPos |> Position.div canvasZoom |> buildInCanvas


inCanvasToViewport : Viewport -> Canvas -> ZoomLevel -> InCanvas -> Viewport
inCanvasToViewport (Viewport erdPos) (Canvas canvasPos) canvasZoom (InCanvas pos) =
    pos |> Position.mult canvasZoom |> Position.add canvasPos |> Position.add erdPos |> buildViewport


canvasToInCanvas : Canvas -> Canvas -> InCanvas
canvasToInCanvas (Canvas canvasPos) (Canvas pos) =
    pos |> Position.sub canvasPos |> buildInCanvas


stylesViewport : Viewport -> List (Attribute msg)
stylesViewport (Viewport pos) =
    [ style "left" (String.fromFloat pos.left ++ "px"), style "top" (String.fromFloat pos.top ++ "px") ]


styleCanvas : Canvas -> ZoomLevel -> Attribute msg
styleCanvas (Canvas pos) zoom =
    style "transform" ("translate(" ++ String.fromFloat pos.left ++ "px, " ++ String.fromFloat pos.top ++ "px) scale(" ++ String.fromFloat zoom ++ ")")


stylesTransformInCanvas : InCanvas -> Attribute msg
stylesTransformInCanvas (InCanvas pos) =
    style "transform" ("translate(" ++ String.fromFloat pos.left ++ "px, " ++ String.fromFloat pos.top ++ "px)")


stylesGrid : Grid -> List (Attribute msg)
stylesGrid (Grid pos) =
    [ style "left" (String.fromFloat pos.left ++ "px"), style "top" (String.fromFloat pos.top ++ "px") ]


toStringRoundViewport : Viewport -> String
toStringRoundViewport (Viewport pos) =
    Position.toStringRound pos


toStringRoundCanvas : Canvas -> String
toStringRoundCanvas (Canvas pos) =
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


encodeCanvas : Canvas -> Value
encodeCanvas (Canvas pos) =
    Encode.notNullObject
        [ ( "left", pos.left |> Encode.float )
        , ( "top", pos.top |> Encode.float )
        ]


decodeCanvas : Decode.Decoder Canvas
decodeCanvas =
    Decode.map2 (\l t -> Position l t |> buildCanvas)
        (Decode.field "left" Decode.float)
        (Decode.field "top" Decode.float)


encodeGrid : Grid -> Value
encodeGrid (Grid pos) =
    Encode.notNullObject
        [ ( "left", pos.left |> alignCoord |> Encode.float )
        , ( "top", pos.top |> alignCoord |> Encode.float )
        ]


decodeGrid : Decode.Decoder Grid
decodeGrid =
    Decode.map2 (\l t -> Position l t |> buildGrid)
        (Decode.field "left" Decode.float)
        (Decode.field "top" Decode.float)
