module Libs.Delta exposing (Delta, fromTuple)


type alias Delta =
    { dx : Float, dy : Float }


fromTuple : ( Float, Float ) -> Delta
fromTuple ( dx, dy ) =
    Delta dx dy
