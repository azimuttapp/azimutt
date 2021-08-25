module Libs.Position exposing (Position, add, sub)


type alias Position =
    { left : Float, top : Float }


add : Position -> Position -> Position
add delta pos =
    Position (pos.left + delta.left) (pos.top + delta.top)


sub : Position -> Position -> Position
sub delta pos =
    Position (pos.left - delta.left) (pos.top - delta.top)
