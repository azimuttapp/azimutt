module Libs.Area exposing (Area, center, doOverlap, isInside, move, scale, size)

import Libs.Position exposing (Position)
import Libs.Size exposing (Size)


type alias Area =
    { left : Float, top : Float, right : Float, bottom : Float }


center : Area -> Position
center area =
    Position ((area.left + area.right) / 2) ((area.top + area.bottom) / 2)


move : Position -> Area -> Area
move vector area =
    Area (area.left + vector.left) (area.top + vector.top) (area.right + vector.left) (area.bottom + vector.top)


scale : Float -> Area -> Area
scale factor area =
    Area (area.left * factor) (area.top * factor) (area.right * factor) (area.bottom * factor)


size : Area -> Size
size area =
    Size (area.right - area.left) (area.bottom - area.top)


topLeft : Area -> Position
topLeft area =
    Position area.left area.top


topRight : Area -> Position
topRight area =
    Position area.right area.top


bottomLeft : Area -> Position
bottomLeft area =
    Position area.left area.bottom


bottomRight : Area -> Position
bottomRight area =
    Position area.right area.bottom


isInside : Area -> Position -> Bool
isInside area point =
    area.left <= point.left && point.left <= area.right && area.top <= point.top && point.top <= area.bottom


doOverlap : Area -> Area -> Bool
doOverlap area item =
    isInside area (topLeft item) || isInside area (topRight item) || isInside area (bottomLeft item) || isInside area (bottomRight item)
