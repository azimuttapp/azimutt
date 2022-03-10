module Libs.Html.Attributes exposing (ariaControls, ariaCurrent, ariaDescribedby, ariaExpanded, ariaHaspopup, ariaHidden, ariaLabel, ariaLabelledby, ariaLive, ariaModal, ariaOrientation, computeStyles, css, hrefBlank, none, role, track, when)

import Html exposing (Attribute)
import Html.Attributes exposing (attribute, class, classList, href, rel, target)
import Libs.Bool as B
import Libs.Models exposing (Text, TrackEvent)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind exposing (TwClass)



-- sorted alphabetically


ariaControls : HtmlId -> Attribute msg
ariaControls targetId =
    attribute "aria-controls" targetId


ariaCurrent : Text -> Attribute msg
ariaCurrent text =
    attribute "aria-current" text


ariaDescribedby : HtmlId -> Attribute msg
ariaDescribedby targetId =
    attribute "aria-describedby" targetId


ariaExpanded : Bool -> Attribute msg
ariaExpanded value =
    attribute "aria-expanded" (B.toString value)


ariaHaspopup : Bool -> Attribute msg
ariaHaspopup value =
    attribute "aria-haspopup" (B.toString value)


ariaHidden : Bool -> Attribute msg
ariaHidden value =
    attribute "aria-hidden" (B.toString value)


ariaLabel : Text -> Attribute msg
ariaLabel text =
    attribute "aria-label" text


ariaLabelledby : HtmlId -> Attribute msg
ariaLabelledby targetId =
    attribute "aria-labelledby" targetId


ariaLive : Text -> Attribute msg
ariaLive text =
    attribute "aria-live" text


ariaModal : Bool -> Attribute msg
ariaModal value =
    attribute "aria-modal" (B.toString value)


ariaOrientation : Text -> Attribute msg
ariaOrientation text =
    attribute "aria-orientation" text


css : List TwClass -> Attribute msg
css values =
    values |> computeStyles |> class


computeStyles : List TwClass -> TwClass
computeStyles values =
    values
        |> List.concatMap (String.split " ")
        |> List.map String.trim
        |> List.filter (\v -> v /= "")
        |> String.join " "


hrefBlank : String -> List (Attribute msg)
hrefBlank url =
    [ href url, target "_blank", rel "noopener" ]


when : Bool -> Attribute msg -> Attribute msg
when p attr =
    if p then
        attr

    else
        classList []


none : Attribute msg
none =
    classList []


role : String -> Attribute msg
role text =
    attribute "role" text


track : TrackEvent -> List (Attribute msg)
track event =
    if event.enabled then
        attribute "data-track-event" event.name :: (event.details |> List.map (\( k, v ) -> attribute ("data-track-event-" ++ k) v))

    else
        []
