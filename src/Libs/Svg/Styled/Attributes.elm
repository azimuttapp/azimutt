module Libs.Svg.Styled.Attributes exposing (vectorEffect)

import Html.Styled.Attributes exposing (attribute)
import Svg.Styled exposing (Attribute)


vectorEffect : String -> Attribute msg
vectorEffect value =
    attribute "vector-effect" value
