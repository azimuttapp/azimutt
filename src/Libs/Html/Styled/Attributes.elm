module Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHidden, ariaLabel, track)

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes exposing (attribute)
import Libs.Bool as B
import Libs.Models exposing (Text, TrackEvent)


ariaHidden : Bool -> Attribute msg
ariaHidden value =
    attribute "aria-hidden" (B.toString value)


ariaLabel : Text -> Attribute msg
ariaLabel text =
    attribute "aria-label" text


ariaExpanded : Bool -> Attribute msg
ariaExpanded value =
    attribute "aria-expanded" (B.toString value)


track : TrackEvent -> List (Attribute msg)
track event =
    attribute "data-track-event" event.name :: (event.details |> List.map (\( k, v ) -> attribute ("data-track-event-" ++ k) v))
