module Libs.Html.Styled.Events exposing (WheelEvent, onWheel)

import Html.Styled exposing (Attribute)
import Html.Styled.Events
import Json.Decode as Decode
import Libs.Html.Events as Events


type alias WheelEvent =
    Events.WheelEvent


onWheel : (WheelEvent -> msg) -> Attribute msg
onWheel callback =
    let
        preventDefaultAndStopPropagation : msg -> { message : msg, stopPropagation : Bool, preventDefault : Bool }
        preventDefaultAndStopPropagation msg =
            { message = msg, stopPropagation = True, preventDefault = True }
    in
    Html.Styled.Events.custom "wheel" (Decode.map preventDefaultAndStopPropagation (Events.wheelEventDecoder callback))
