module Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHidden, ariaLabel)

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes exposing (attribute)
import Libs.Bool as B
import Libs.Models exposing (Text)


ariaHidden : Bool -> Attribute msg
ariaHidden value =
    attribute "aria-hidden" (B.toString value)


ariaLabel : Text -> Attribute msg
ariaLabel text =
    attribute "aria-label" text


ariaExpanded : Bool -> Attribute msg
ariaExpanded value =
    attribute "aria-expanded" (B.toString value)
