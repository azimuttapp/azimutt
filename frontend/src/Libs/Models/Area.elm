module Libs.Models.Area exposing (Area, AreaLike, debug, decode, encode, inside, merge, normalize, overlap, toStringRound, zero)

import Html exposing (Attribute, Html, text)
import Html.Attributes exposing (class)
import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Json.Encode as Encode
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Libs.Tailwind exposing (TwClass)


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


styleTransform : AreaLike a -> List (Attribute msg)
styleTransform area =
    Position.styleTransform area.position :: Size.styles area.size


encode : Area -> Value
encode value =
    Encode.notNullObject
        [ ( "position", value.position |> Position.encode )
        , ( "size", value.size |> Size.encode )
        ]


decode : Decode.Decoder Area
decode =
    Decode.map2 Area
        (Decode.field "position" Position.decode)
        (Decode.field "size" Size.decode)


debug : String -> TwClass -> AreaLike a -> Html msg
debug name classes area =
    Html.div ([ class (classes ++ " z-max absolute pointer-events-none whitespace-nowrap border") ] ++ styleTransform area) [ text (name ++ ": " ++ toStringRound area) ]
