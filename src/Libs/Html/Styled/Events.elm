module Libs.Html.Styled.Events exposing (PointerEvent, WheelEvent, onPointerDown, onPointerUp, onWheel, preventPointerDown, stopClick, stopPointerDown)

import Html.Styled exposing (Attribute)
import Html.Styled.Events as Events
import Json.Decode as Decode
import Libs.Html.Events



-- sorted alphabetically


type alias PointerEvent =
    Libs.Html.Events.PointerEvent


onPointerDown : (PointerEvent -> msg) -> Attribute msg
onPointerDown msg =
    Events.on "pointerdown" (Libs.Html.Events.pointerDecoder |> Decode.map msg)


onPointerUp : (PointerEvent -> msg) -> Attribute msg
onPointerUp msg =
    Events.on "pointerup" (Libs.Html.Events.pointerDecoder |> Decode.map msg)


type alias WheelEvent =
    Libs.Html.Events.WheelEvent


onWheel : (WheelEvent -> msg) -> Attribute msg
onWheel callback =
    let
        preventDefaultAndStopPropagation : msg -> { message : msg, stopPropagation : Bool, preventDefault : Bool }
        preventDefaultAndStopPropagation msg =
            { message = msg, stopPropagation = True, preventDefault = True }
    in
    Events.custom "wheel" (Libs.Html.Events.wheelDecoder |> Decode.map (callback >> preventDefaultAndStopPropagation))


preventPointerDown : (PointerEvent -> msg) -> Attribute msg
preventPointerDown msg =
    Events.preventDefaultOn "pointerdown" (Libs.Html.Events.pointerDecoder |> Decode.map (\e -> ( msg e, True )))


stopClick : (PointerEvent -> msg) -> Attribute msg
stopClick msg =
    Events.stopPropagationOn "click" (Libs.Html.Events.pointerDecoder |> Decode.map (\e -> ( msg e, True )))


stopPointerDown : (PointerEvent -> msg) -> Attribute msg
stopPointerDown msg =
    Events.stopPropagationOn "pointerdown" (Libs.Html.Events.pointerDecoder |> Decode.map (\e -> ( msg e, True )))
