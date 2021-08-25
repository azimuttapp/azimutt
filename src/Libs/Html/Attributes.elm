module Libs.Html.Attributes exposing (ariaControls, ariaDescribedBy, ariaExpanded, ariaHidden, ariaLabel, ariaLabelledBy, role)

import Html exposing (Attribute)
import Html.Attributes exposing (attribute)
import Libs.Bool as B
import Libs.Models exposing (HtmlId, Text)


role : String -> Attribute msg
role text =
    attribute "role" text


ariaExpanded : Bool -> Attribute msg
ariaExpanded value =
    attribute "aria-expanded" (B.toString value)


ariaHidden : Bool -> Attribute msg
ariaHidden value =
    attribute "aria-hidden" (B.toString value)


ariaControls : HtmlId -> Attribute msg
ariaControls targetId =
    attribute "aria-controls" targetId


ariaLabel : Text -> Attribute msg
ariaLabel text =
    attribute "aria-label" text


ariaLabelledBy : HtmlId -> Attribute msg
ariaLabelledBy targetId =
    attribute "aria-labelledby" targetId


ariaDescribedBy : HtmlId -> Attribute msg
ariaDescribedBy targetId =
    attribute "aria-describedby" targetId
