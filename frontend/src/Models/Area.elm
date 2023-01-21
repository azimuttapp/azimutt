module Models.Area exposing (Canvas, CanvasLike, Diagram, Grid, GridLike, Viewport, ViewportLike, centerCanvas, centerCanvasGrid, centerViewport, debugCanvas, debugViewport, diagramToCanvas, divCanvas, fromCanvas, mergeCanvas, multCanvas, offGrid, overlapCanvas, styleTransformCanvas, styleTransformViewport, stylesGrid, stylesViewport, toStringRoundCanvas, toStringRoundViewport, topLeftCanvasGrid, topRightCanvasGrid, zeroCanvas)

import Html exposing (Attribute, Html, div, text)
import Html.Attributes exposing (class)
import Libs.Models.Area as Area exposing (Area)
import Libs.Models.Delta as Delta
import Libs.Tailwind exposing (TwClass)
import Models.Position as Position
import Models.Size as Size


type alias Viewport =
    { position : Position.Viewport, size : Size.Viewport }


type alias Diagram =
    { position : Position.Diagram, size : Size.Canvas }


type alias Canvas =
    { position : Position.Canvas, size : Size.Canvas }


type alias Grid =
    { position : Position.Grid, size : Size.Canvas }


type alias ViewportLike x =
    { x | position : Position.Viewport, size : Size.Viewport }


type alias CanvasLike x =
    { x | position : Position.Canvas, size : Size.Canvas }


type alias GridLike x =
    { x | position : Position.Grid, size : Size.Canvas }


zeroCanvas : Canvas
zeroCanvas =
    Canvas Position.zeroCanvas Size.zeroCanvas


fromCanvas : Position.Canvas -> Position.Canvas -> Canvas
fromCanvas p1 p2 =
    { position = Position.minCanvas p1 p2, size = Position.sizeCanvas p1 p2 }


centerViewport : { x | position : Position.Viewport, size : Size.Viewport } -> Position.Viewport
centerViewport area =
    area.position |> Position.moveViewport (area.size |> Size.divViewport 2 |> Size.toTupleViewport |> Delta.fromTuple)


centerCanvas : Canvas -> Position.Canvas
centerCanvas area =
    area.position |> Position.moveCanvas (area.size |> Size.divCanvas 2 |> Size.toTupleCanvas |> Delta.fromTuple)


offGrid : GridLike a -> Canvas
offGrid area =
    Canvas (area.position |> Position.offGrid) area.size


topLeftCanvasGrid : GridLike a -> Position.Canvas
topLeftCanvasGrid area =
    area.position |> Position.offGrid


topRightCanvasGrid : GridLike a -> Position.Canvas
topRightCanvasGrid area =
    area.position |> Position.offGrid |> Position.moveCanvas { dx = area.size |> Size.extractCanvas |> .width, dy = 0 }


centerCanvasGrid : GridLike a -> Position.Canvas
centerCanvasGrid area =
    area.position |> Position.offGrid |> Position.moveCanvas (area.size |> Size.divCanvas 2 |> Size.deltaCanvas)


multCanvas : Float -> Canvas -> Canvas
multCanvas factor area =
    Canvas (area.position |> Position.multCanvas factor) (area.size |> Size.multCanvas factor)


divCanvas : Float -> Canvas -> Canvas
divCanvas factor area =
    Canvas (area.position |> Position.divCanvas factor) (area.size |> Size.divCanvas factor)


diagramToCanvas : Position.Diagram -> Diagram -> Canvas
diagramToCanvas canvasPos { position, size } =
    -- size is already on Canvas, don't adjust it
    Canvas (position |> Position.diagramToCanvas canvasPos) size


mergeCanvas : List (CanvasLike a) -> Maybe Canvas
mergeCanvas areas =
    areas
        |> List.map (\{ position, size } -> Area (Position.extractCanvas position) (Size.extractCanvas size))
        |> Area.merge
        |> Maybe.map (\{ position, size } -> Canvas (Position.canvas position) (Size.canvas size))


overlapCanvas : CanvasLike b -> CanvasLike a -> Bool
overlapCanvas area2 area1 =
    Area.overlap
        (Area (Position.extractCanvas area2.position) (Size.extractCanvas area2.size))
        (Area (Position.extractCanvas area1.position) (Size.extractCanvas area1.size))


stylesViewport : ViewportLike a -> List (Attribute msg)
stylesViewport area =
    Position.stylesViewport area.position ++ Size.stylesViewport area.size


stylesGrid : GridLike a -> List (Attribute msg)
stylesGrid area =
    Position.stylesGrid area.position ++ Size.stylesCanvas area.size


styleTransformViewport : ViewportLike a -> List (Attribute msg)
styleTransformViewport area =
    Position.styleTransformViewport area.position :: Size.stylesViewport area.size


styleTransformCanvas : CanvasLike a -> List (Attribute msg)
styleTransformCanvas area =
    Position.styleTransformCanvas area.position :: Size.stylesCanvas area.size


debugViewport : String -> TwClass -> ViewportLike a -> Html msg
debugViewport name classes area =
    div ([ class (classes ++ " z-max absolute pointer-events-none whitespace-nowrap border") ] ++ stylesViewport area) [ text (name ++ ": " ++ toStringRoundViewport area) ]


debugCanvas : String -> TwClass -> CanvasLike a -> Html msg
debugCanvas name classes area =
    div ([ class (classes ++ " z-max absolute pointer-events-none whitespace-nowrap border") ] ++ styleTransformCanvas area) [ text (name ++ ": " ++ toStringRoundCanvas area) ]


toStringRoundViewport : ViewportLike a -> String
toStringRoundViewport area =
    Area.toStringRound (Area (Position.extractViewport area.position) (Size.extractViewport area.size))


toStringRoundCanvas : CanvasLike a -> String
toStringRoundCanvas area =
    Area.toStringRound (Area (Position.extractCanvas area.position) (Size.extractCanvas area.size))
