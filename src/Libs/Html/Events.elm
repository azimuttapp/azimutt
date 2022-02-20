module Libs.Html.Events exposing (PointerEvent, WheelEvent, onPointerDown, onPointerUp, onWheel, pointerDecoder, preventPointerDown, stopClick, stopPointerDown, wheelDecoder)

import Html exposing (Attribute)
import Html.Events exposing (preventDefaultOn, stopPropagationOn)
import Html.Events.Extra.Mouse exposing (Button)
import Html.Events.Extra.Pointer as Pointer
import Json.Decode as Decode
import Libs.Delta exposing (Delta)
import Libs.Models.Position as Position exposing (Position)



-- sorted alphabetically


type alias PointerEvent =
    { position : Position, ctrl : Bool, alt : Bool, shift : Bool, button : Button }


onPointerDown : (PointerEvent -> msg) -> Attribute msg
onPointerDown msg =
    Html.Events.on "pointerdown" (pointerDecoder |> Decode.map msg)


onPointerUp : (PointerEvent -> msg) -> Attribute msg
onPointerUp msg =
    Html.Events.on "pointerup" (pointerDecoder |> Decode.map msg)


type alias FileEvent =
    { inputId : String, file : List FileInfo }


type alias FileInfo =
    { name : String, kind : String, size : Int, lastModified : Int }


onFileChange : (FileEvent -> msg) -> Attribute msg
onFileChange callback =
    -- Elm: no error message when decoder fail, hard to get it correct :(
    let
        fileDecoder : Decode.Decoder FileInfo
        fileDecoder =
            Decode.map4 FileInfo
                (Decode.field "name" Decode.string)
                (Decode.field "type" Decode.string)
                (Decode.field "size" Decode.int)
                (Decode.field "lastModified" Decode.int)

        decoder : Decode.Decoder msg
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


preventPointerDown : (PointerEvent -> msg) -> Attribute msg
preventPointerDown msg =
    preventDefaultOn "pointerdown" (pointerDecoder |> Decode.map (\e -> ( msg e, True )))


stopClick : msg -> Attribute msg
stopClick m =
    stopPropagationOn "click" (Decode.succeed ( m, True ))


stopPointerDown : (PointerEvent -> msg) -> Attribute msg
stopPointerDown msg =
    stopPropagationOn "pointerdown" (pointerDecoder |> Decode.map (\e -> ( msg e, True )))



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
                , button = e.pointer.button
                }
            )


wheelDecoder : Decode.Decoder WheelEvent
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
