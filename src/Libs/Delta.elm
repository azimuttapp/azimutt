module Libs.Delta exposing (Delta, adjust, fromTuple, move, negate)

import Libs.Models.Position exposing (Position)
import Libs.Models.ZoomLevel exposing (ZoomLevel)


type alias Delta =
    { dx : Float, dy : Float }


fromTuple : ( Float, Float ) -> Delta
fromTuple ( dx, dy ) =
    Delta dx dy


negate : Delta -> Delta
negate delta =
    Delta -delta.dx -delta.dy


adjust : ZoomLevel -> Delta -> Delta
adjust zoom delta =
    Delta (delta.dx * zoom) (delta.dy * zoom)


move : Position -> Delta -> Position
move position delta =
    Position (position.left + delta.dx) (position.top + delta.dy)
