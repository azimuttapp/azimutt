module Libs.Html.Events exposing (WheelEvent, onWheel, stopClick, wheelDecoder)

import Html exposing (Attribute)
import Html.Events exposing (stopPropagationOn)
import Json.Decode as Decode exposing (Decoder)
import Libs.Delta exposing (Delta)
import Libs.Models.Position exposing (Position)


stopClick : msg -> Attribute msg
stopClick m =
    stopPropagationOn "click" (Decode.succeed ( m, True ))


type alias FileEvent =
    { inputId : String, file : List FileInfo }


type alias FileInfo =
    { name : String, kind : String, size : Int, lastModified : Int }


onFileChange : (FileEvent -> msg) -> Attribute msg
onFileChange callback =
    -- Elm: no error message when decoder fail, hard to get it correct :(
    let
        fileDecoder : Decoder FileInfo
        fileDecoder =
            Decode.map4 FileInfo
                (Decode.field "name" Decode.string)
                (Decode.field "type" Decode.string)
                (Decode.field "size" Decode.int)
                (Decode.field "lastModified" Decode.int)

        decoder : Decoder msg
        decoder =
            Decode.field "target"
                (Decode.map2 FileEvent
                    (Decode.field "id" Decode.string)
                    (Decode.field "files" (Decode.list fileDecoder))
                )
                |> Decode.map callback

        preventDefaultAndStopPropagation : msg -> { message : msg, stopPropagation : Bool, preventDefault : Bool }
        preventDefaultAndStopPropagation msg =
            { message = msg, stopPropagation = True, preventDefault = True }
    in
    Html.Events.custom "change" (Decode.map preventDefaultAndStopPropagation decoder)


type alias WheelEvent =
    { position : Position
    , delta : Delta
    , ctrl : Bool
    , alt : Bool
    , shift : Bool
    , meta : Bool
    }


onWheel : (WheelEvent -> msg) -> Attribute msg
onWheel callback =
    let
        preventDefaultAndStopPropagation : msg -> { message : msg, stopPropagation : Bool, preventDefault : Bool }
        preventDefaultAndStopPropagation msg =
            { message = msg, stopPropagation = True, preventDefault = True }
    in
    Html.Events.custom "wheel" (wheelDecoder |> Decode.map (callback >> preventDefaultAndStopPropagation))


wheelDecoder : Decoder WheelEvent
wheelDecoder =
    Decode.map6 WheelEvent
        (Decode.map2 Position
            (Decode.field "pageX" Decode.float)
            (Decode.field "pageY" Decode.float)
        )
        (Decode.map2 Delta
            (Decode.field "deltaX" Decode.float)
            (Decode.field "deltaY" Decode.float)
        )
        (Decode.field "ctrlKey" Decode.bool)
        (Decode.field "altKey" Decode.bool)
        (Decode.field "shiftKey" Decode.bool)
        (Decode.field "metaKey" Decode.bool)
