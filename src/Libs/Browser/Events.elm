module Libs.Browser.Events exposing (EventTarget, KeyboardEvent, keyboardEventDecoder)

import Json.Decode as Decode


type alias KeyboardEvent =
    { key : String, keyCode : Int, ctrlKey : Bool, shiftKey : Bool, altKey : Bool, metaKey : Bool, repeat : Bool, target : EventTarget }


type alias EventTarget =
    { localName : String, id : String, className : String }


keyboardEventDecoder : Decode.Decoder KeyboardEvent
keyboardEventDecoder =
    Decode.map8 KeyboardEvent
        (Decode.field "key" Decode.string)
        (Decode.field "keyCode" Decode.int)
        (Decode.field "ctrlKey" Decode.bool)
        (Decode.field "shiftKey" Decode.bool)
        (Decode.field "altKey" Decode.bool)
        (Decode.field "metaKey" Decode.bool)
        (Decode.field "repeat" Decode.bool)
        (Decode.field "target" eventTargetDecoder)


eventTargetDecoder : Decode.Decoder EventTarget
eventTargetDecoder =
    Decode.map3 EventTarget
        (Decode.field "localName" Decode.string)
        (Decode.field "id" Decode.string)
        (Decode.field "className" Decode.string)
