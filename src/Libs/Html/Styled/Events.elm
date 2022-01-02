module Libs.Html.Styled.Events exposing (PointerEvent, WheelEvent, onPointerDown, onPointerDownPreventDefault, onPointerDownStopPropagation, onPointerUp, onWheel)

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


onPointerDownPreventDefault : (PointerEvent -> msg) -> Attribute msg
onPointerDownPreventDefault msg =
    Events.preventDefaultOn "pointerdown" (pointerDecoder |> Decode.map (\e -> ( msg e, True )))


onPointerDownStopPropagation : (PointerEvent -> msg) -> Attribute msg
onPointerDownStopPropagation msg =
    Events.stopPropagationOn "pointerdown" (pointerDecoder |> Decode.map (\e -> ( msg e, True )))


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
