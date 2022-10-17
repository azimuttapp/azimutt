module Libs.Svg.Utils exposing (circle, curveTo, lineTo, moveTo)

import Libs.Models.Position exposing (Position)
import Svg exposing (Attribute, Svg)
import Svg.Attributes exposing (cx, cy, r)


moveTo : Position -> String
moveTo pos =
    "M" ++ point pos


lineTo : Position -> String
lineTo pos =
    "L" ++ point pos


curveTo : Position -> Position -> Position -> String
curveTo from anchor to =
    "C" ++ point from ++ " " ++ point anchor ++ " " ++ point to


point : Position -> String
point p =
    String.fromFloat p.left ++ "," ++ String.fromFloat p.top


circle : Position -> Float -> List (Attribute msg) -> Svg msg
circle pos radius attrs =
    Svg.circle (cx (String.fromFloat pos.left) :: cy (String.fromFloat pos.top) :: r (String.fromFloat radius) :: attrs) []
