module Libs.Html.Attributes exposing (ariaActivedescendant, ariaChecked, ariaControls, ariaCurrent, ariaDescribedby, ariaExpanded, ariaHaspopup, ariaHidden, ariaLabel, ariaLabelledby, ariaLive, ariaModal, ariaOrientation, css, hrefBlank, role, styles, track)

import Html exposing (Attribute)
import Html.Attributes exposing (attribute, class, href, rel, target)
import Libs.Bool as B
import Libs.Maybe as Maybe
import Libs.Models exposing (Text)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind exposing (TwClass)
import Models.OrganizationId exposing (OrganizationId)
import Models.TrackEvent exposing (TrackClick, TrackEvent)



-- sorted alphabetically


ariaActivedescendant : HtmlId -> Attribute msg
ariaActivedescendant targetId =
    attribute "aria-activedescendant" targetId


ariaChecked : Bool -> Attribute msg
ariaChecked value =
    attribute "aria-checked" (B.toString value)


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


ariaHaspopup : String -> Attribute msg
ariaHaspopup value =
    attribute "aria-haspopup" value


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
    values |> styles |> class


styles : List TwClass -> TwClass
styles values =
    values
        |> List.concatMap (String.split " ")
        |> List.map String.trim
        |> List.filter (\v -> v /= "")
        |> String.join " "


hrefBlank : String -> List (Attribute msg)
hrefBlank url =
    [ href url, target "_blank", rel "noopener" ]


role : String -> Attribute msg
role text =
    attribute "role" text


track : TrackClick -> List (Attribute msg)
track event =
    -- MUST stay sync with frontend/ts-src/index.ts:407#trackClick
    let
        moreDetails : List ( String, OrganizationId )
        moreDetails =
            (event.organization |> Maybe.map (\id -> ( "organization", id )) |> Maybe.toList)
                ++ (event.project |> Maybe.map (\id -> ( "project", id )) |> Maybe.toList)
    in
    attribute "data-track-event" event.name :: ((moreDetails ++ event.details) |> List.map (\( k, v ) -> attribute ("data-track-event-" ++ k) v))
