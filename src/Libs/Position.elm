module Libs.Position exposing (Position, add, div, from, sub)


type alias Position =
    { left : Float, top : Float }


from : ( Float, Float ) -> Position
from ( left, top ) =
    Position left top


add : Position -> Position -> Position
add delta pos =
    Position (pos.left + delta.left) (pos.top + delta.top)


sub : Position -> Position -> Position
sub delta pos =
    Position (pos.left - delta.left) (pos.top - delta.top)


div : Float -> Position -> Position
div factor pos =
    Position (pos.left / factor) (pos.top / factor)
