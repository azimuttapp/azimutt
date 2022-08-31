module Models.Area exposing (Canvas, CanvasGridLike, CanvasLike, Diagram, Viewport, ViewportLike, centerCanvas, centerViewport, diagramToCanvas, divCanvas, fromCanvas, mergeCanvas, overlapCanvas, styleTransformCanvas, toStringRoundCanvas, toStringRoundViewport, topLeftCanvasGrid, topRightCanvasGrid, zeroCanvas)

import Html exposing (Attribute)
import Libs.Delta as Delta
import Libs.Models.Area as Area exposing (Area)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Position as Position
import Models.Size as Size


type alias Viewport =
    { position : Position.Viewport, size : Size.Viewport }


type alias Diagram =
    { position : Position.Diagram, size : Size.Canvas }


type alias Canvas =
    { position : Position.Canvas, size : Size.Canvas }


type alias ViewportLike x =
    { x | position : Position.Viewport, size : Size.Viewport }


type alias CanvasLike x =
    { x | position : Position.Canvas, size : Size.Canvas }


type alias CanvasGridLike x =
    { x | position : Position.CanvasGrid, size : Size.Canvas }


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


topLeftCanvasGrid : CanvasGridLike a -> Position.Canvas
topLeftCanvasGrid area =
    area.position |> Position.offGrid


topRightCanvasGrid : CanvasGridLike a -> Position.Canvas
topRightCanvasGrid area =
    area.position |> Position.offGrid |> Position.moveCanvas { dx = area.size |> Size.extractCanvas |> .width, dy = 0 }


divCanvas : Float -> Canvas -> Canvas
divCanvas factor area =
    Canvas (area.position |> Position.divCanvas factor) (area.size |> Size.divCanvas factor)


diagramToCanvas : Position.Diagram -> ZoomLevel -> Diagram -> Canvas
diagramToCanvas canvasPos canvasZoom { position, size } =
    Canvas (position |> Position.diagramToCanvas canvasPos) size |> divCanvas canvasZoom


mergeCanvas : List (CanvasLike a) -> Maybe Canvas
mergeCanvas areas =
    areas
        |> List.map (\{ position, size } -> Area (Position.extractCanvas position) (Size.extractCanvas size))
        |> Area.merge
        |> Maybe.map (\{ position, size } -> Canvas (Position.buildCanvas position) (Size.buildCanvas size))


overlapCanvas : CanvasLike a -> CanvasLike b -> Bool
overlapCanvas area1 area2 =
    Area.overlap
        (Area (Position.extractCanvas area1.position) (Size.extractCanvas area1.size))
        (Area (Position.extractCanvas area2.position) (Size.extractCanvas area2.size))


styleTransformCanvas : Canvas -> List (Attribute msg)
styleTransformCanvas area =
    Position.styleTransformCanvas area.position :: Size.stylesCanvas area.size


toStringRoundViewport : ViewportLike a -> String
toStringRoundViewport area =
    Area.toStringRound (Area (Position.extractViewport area.position) (Size.extractViewport area.size))


toStringRoundCanvas : CanvasLike a -> String
toStringRoundCanvas area =
    Area.toStringRound (Area (Position.extractCanvas area.position) (Size.extractCanvas area.size))
