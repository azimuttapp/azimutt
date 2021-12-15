module Libs.Html.Styled.Attributes exposing (ariaControls, ariaCurrent, ariaDescribedby, ariaExpanded, ariaHaspopup, ariaHidden, ariaLabel, ariaLabelledby, ariaLive, ariaModal, ariaOrientation, onPointerDown, onPointerUp, role, track)

import Html.Events.Extra.Mouse as Mouse
import Html.Events.Extra.Pointer as Pointer exposing (Event)
import Html.Styled exposing (Attribute)
import Html.Styled.Attributes exposing (attribute)
import Html.Styled.Events as Events
import Json.Decode as Decode
import Libs.Bool as B
import Libs.Models exposing (Text, TrackEvent)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position exposing (Position)



-- sorted alphabetically


ariaControls : Text -> Attribute msg
ariaControls text =
    attribute "aria-controls" text


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


ariaLabelledby : Text -> Attribute msg
ariaLabelledby text =
    attribute "aria-labelledby" text


ariaLive : Text -> Attribute msg
ariaLive text =
    attribute "aria-live" text


ariaModal : Bool -> Attribute msg
ariaModal value =
    attribute "aria-modal" (B.toString value)


ariaOrientation : Text -> Attribute msg
ariaOrientation text =
    attribute "aria-orientation" text


onPointerDown : (Position -> msg) -> Attribute msg
onPointerDown msg =
    Events.on "pointerdown" (Mouse.eventDecoder |> Decode.map (.pagePos >> Position.fromTuple >> msg))


onPointerUp : (Event -> msg) -> Attribute msg
onPointerUp msg =
    Events.on "pointerup" (Pointer.eventDecoder |> Decode.map msg)


role : String -> Attribute msg
role text =
    attribute "role" text


track : TrackEvent -> List (Attribute msg)
track event =
    if event.enabled then
        attribute "data-track-event" event.name :: (event.details |> List.map (\( k, v ) -> attribute ("data-track-event-" ++ k) v))

    else
        []
