module Libs.Html.Attributes exposing (ariaControls, ariaDescribedBy, ariaExpanded, ariaHidden, ariaLabel, ariaLabelledBy, role, track)

import Html exposing (Attribute)
import Html.Attributes exposing (attribute)
import Libs.Bool as B
import Libs.Models exposing (HtmlId, Text, TrackEvent)


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


track : TrackEvent -> List (Attribute msg)
track event =
    attribute "data-track-event" event.name :: (event.details |> List.map (\( k, v ) -> attribute ("data-track-event-" ++ k) v))
