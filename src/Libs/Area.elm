module Libs.Area exposing (Area, center, inside, move, overlap, scale, size)

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


inside : Position -> Area -> Bool
inside point area =
    area.left <= point.left && point.left <= area.right && area.top <= point.top && point.top <= area.bottom


overlap : Area -> Area -> Bool
overlap area1 area2 =
    not
        -- area2 is on the left of area1
        ((area2.right <= area1.left)
            -- area2 is on the right of area1
            || (area2.left >= area1.right)
            -- area2 is below of area1
            || (area2.top >= area1.bottom)
            -- area2 is above of area1
            || (area2.bottom <= area1.top)
        )
