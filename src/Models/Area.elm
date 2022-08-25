module Models.Area exposing (Canvas, InCanvas, InCanvasLike, Viewport, adaptCanvas, centerInCanvas, centerViewport, divInCanvas, fromInCanvas, mergeInCanvas, overlapInCanvas, zeroInCanvas)

import Libs.Delta as Delta
import Libs.Models.Area as Area exposing (Area)
import Libs.Models.Size as Size exposing (Size)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Position as Position


type alias Viewport =
    { position : Position.Viewport, size : Size }


type alias Canvas =
    { position : Position.Canvas, size : Size }


type alias InCanvas =
    { position : Position.InCanvas, size : Size }


type alias InCanvasLike x =
    { x | position : Position.InCanvas, size : Size }


zeroInCanvas : InCanvas
zeroInCanvas =
    InCanvas Position.zeroInCanvas Size.zero


fromInCanvas : Position.InCanvas -> Position.InCanvas -> InCanvas
fromInCanvas p1 p2 =
    { position = Position.minInCanvas p1 p2, size = Position.sizeInCanvas p1 p2 }


centerViewport : { x | position : Position.Viewport, size : Size } -> Position.Viewport
centerViewport area =
    area.position |> Position.moveViewport (area.size |> Size.div 2 |> Size.toTuple |> Delta.fromTuple)


centerInCanvas : InCanvas -> Position.InCanvas
centerInCanvas area =
    area.position |> Position.moveInCanvas (area.size |> Size.div 2 |> Size.toTuple |> Delta.fromTuple)


divInCanvas : Float -> InCanvas -> InCanvas
divInCanvas factor area =
    InCanvas (area.position |> Position.divInCanvas factor) (area.size |> Size.div factor)


adaptCanvas : Position.Canvas -> ZoomLevel -> Canvas -> InCanvas
adaptCanvas canvasPos canvasZoom { position, size } =
    InCanvas (position |> Position.adaptCanvas canvasPos) size |> divInCanvas canvasZoom


mergeInCanvas : List (InCanvasLike a) -> Maybe InCanvas
mergeInCanvas areas =
    areas
        |> List.map (\{ position, size } -> Area (Position.extractInCanvas position) size)
        |> Area.merge
        |> Maybe.map (\{ position, size } -> InCanvas (Position.buildInCanvas position) size)


overlapInCanvas : InCanvasLike a -> InCanvasLike b -> Bool
overlapInCanvas area1 area2 =
    Area.overlap
        (Area (Position.extractInCanvas area1.position) area1.size)
        (Area (Position.extractInCanvas area2.position) area2.size)
