module Libs.Models.Area exposing (Area, AreaLike, inside, merge, normalize, overlap, toStringRound, zero)

import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)


type alias Area =
    { position : Position, size : Size }


type alias AreaLike x =
    { x | position : Position, size : Size }


zero : Area
zero =
    { position = Position.zero, size = Size.zero }


merge : List (AreaLike a) -> Maybe Area
merge areas =
    Maybe.map4 (\left top right bottom -> Area (Position left top) (Size (right - left) (bottom - top)))
        ((areas |> List.map (\area -> area.position.left)) |> List.minimum)
        (areas |> List.map (\area -> area.position.top) |> List.minimum)
        (areas |> List.map (\area -> area.position.left + area.size.width) |> List.maximum)
        (areas |> List.map (\area -> area.position.top + area.size.height) |> List.maximum)


normalize : Area -> Area
normalize area =
    let
        ( left, width ) =
            if area.size.width < 0 then
                ( area.position.left + area.size.width, -area.size.width )

            else
                ( area.position.left, area.size.width )

        ( top, height ) =
            if area.size.height < 0 then
                ( area.position.top + area.size.height, -area.size.height )

            else
                ( area.position.top, area.size.height )
    in
    Area (Position left top) (Size width height)


inside : Position -> Area -> Bool
inside point area =
    (area.position.left <= point.left)
        && (point.left <= area.position.left + area.size.width)
        && (area.position.top <= point.top)
        && (point.top <= area.position.top + area.size.height)


overlap : AreaLike a -> AreaLike b -> Bool
overlap area1 area2 =
    not
        -- area2 is on the left of area1
        ((area2.position.left + area2.size.width <= area1.position.left)
            -- area2 is on the right of area1
            || (area2.position.left >= area1.position.left + area1.size.width)
            -- area2 is below of area1
            || (area2.position.top >= area1.position.top + area1.size.height)
            -- area2 is above of area1
            || (area2.position.top + area2.size.height <= area1.position.top)
        )


toStringRound : AreaLike a -> String
toStringRound { position, size } =
    Position.toStringRound position ++ " / " ++ Size.toStringRound size
