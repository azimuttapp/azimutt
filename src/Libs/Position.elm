module Libs.Position exposing (Position, add, div, fromTuple, sub, toTuple)


type alias Position =
    { left : Float, top : Float }


fromTuple : ( Float, Float ) -> Position
fromTuple ( left, top ) =
    Position left top


toTuple : Position -> ( Float, Float )
toTuple pos =
    ( pos.left, pos.top )


add : Position -> Position -> Position
add delta pos =
    Position (pos.left + delta.left) (pos.top + delta.top)


sub : Position -> Position -> Position
sub delta pos =
    Position (pos.left - delta.left) (pos.top - delta.top)


div : Float -> Position -> Position
div factor pos =
    Position (pos.left / factor) (pos.top / factor)
