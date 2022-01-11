module Libs.Html.Styled.Events exposing (PointerEvent, WheelEvent, onPointerDown, onPointerUp, onWheel, preventPointerDown, stopClick, stopPointerDown)

import Html.Events.Extra.Pointer as Pointer exposing (Event)
import Html.Styled exposing (Attribute)
import Html.Styled.Events as Events
import Json.Decode as Decode
import Libs.Html.Events as Events
import Libs.Models.Position as Position exposing (Position)



-- sorted alphabetically


type alias PointerEvent =
    { position : Position, ctrl : Bool, alt : Bool, shift : Bool }


onPointerDown : (PointerEvent -> msg) -> Attribute msg
onPointerDown msg =
    Events.on "pointerdown" (pointerDecoder |> Decode.map msg)


onPointerUp : (PointerEvent -> msg) -> Attribute msg
onPointerUp msg =
    Events.on "pointerup" (pointerDecoder |> Decode.map msg)


type alias WheelEvent =
    Events.WheelEvent


onWheel : (WheelEvent -> msg) -> Attribute msg
onWheel callback =
    let
        preventDefaultAndStopPropagation : msg -> { message : msg, stopPropagation : Bool, preventDefault : Bool }
        preventDefaultAndStopPropagation msg =
            { message = msg, stopPropagation = True, preventDefault = True }
    in
    Events.custom "wheel" (Events.wheelDecoder |> Decode.map (callback >> preventDefaultAndStopPropagation))


preventPointerDown : (PointerEvent -> msg) -> Attribute msg
preventPointerDown msg =
    Events.preventDefaultOn "pointerdown" (pointerDecoder |> Decode.map (\e -> ( msg e, True )))


stopClick : (PointerEvent -> msg) -> Attribute msg
stopClick msg =
    Events.stopPropagationOn "click" (pointerDecoder |> Decode.map (\e -> ( msg e, True )))


stopPointerDown : (PointerEvent -> msg) -> Attribute msg
stopPointerDown msg =
    Events.stopPropagationOn "pointerdown" (pointerDecoder |> Decode.map (\e -> ( msg e, True )))



-- HELPERS


pointerDecoder : Decode.Decoder PointerEvent
pointerDecoder =
    Pointer.eventDecoder
        |> Decode.map
            (\e ->
                { position = e.pointer.pagePos |> Position.fromTuple
                , ctrl = e.pointer.keys.ctrl
                , alt = e.pointer.keys.alt
                , shift = e.pointer.keys.shift
                }
            )
