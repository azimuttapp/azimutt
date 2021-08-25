module Libs.Area exposing (Area, center, move, scale, size)

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
