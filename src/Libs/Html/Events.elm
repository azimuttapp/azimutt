module Libs.Html.Events exposing (PointerEvent, WheelEvent, onContextMenu, onPointerDown, onPointerUp, onWheel, pointerDecoder, preventPointerDown, stopClick, stopPointerDown, wheelDecoder)

import Html exposing (Attribute)
import Html.Events exposing (preventDefaultOn, stopPropagationOn)
import Html.Events.Extra.Mouse as Button exposing (Button)
import Json.Decode as Decode
import Libs.Bool as B
import Libs.Models.Delta exposing (Delta)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Models.Position exposing (Position)



-- sorted alphabetically


type alias PointerEvent =
    { position : Position, ctrl : Bool, alt : Bool, shift : Bool, meta : Bool, button : Button }


onContextMenu : Platform -> (PointerEvent -> msg) -> Attribute msg
onContextMenu platform msg =
    Html.Events.custom "contextmenu" (pointerDecoder platform |> Decode.map (\e -> { message = msg e, stopPropagation = True, preventDefault = True }))


onPointerDown : Platform -> (PointerEvent -> msg) -> Attribute msg
onPointerDown platform msg =
    Html.Events.on "pointerdown" (pointerDecoder platform |> Decode.map msg)


onPointerUp : Platform -> (PointerEvent -> msg) -> Attribute msg
onPointerUp platform msg =
    Html.Events.on "pointerup" (pointerDecoder platform |> Decode.map msg)


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


onWheel : Platform -> (WheelEvent -> msg) -> Attribute msg
onWheel platform callback =
    let
        preventDefaultAndStopPropagation : msg -> { message : msg, stopPropagation : Bool, preventDefault : Bool }
        preventDefaultAndStopPropagation msg =
            { message = msg, stopPropagation = True, preventDefault = True }
    in
    Html.Events.custom "wheel" (wheelDecoder platform |> Decode.map (callback >> preventDefaultAndStopPropagation))


preventPointerDown : Platform -> (PointerEvent -> msg) -> Attribute msg
preventPointerDown platform msg =
    preventDefaultOn "pointerdown" (pointerDecoder platform |> Decode.map (\e -> ( msg e, True )))


stopClick : msg -> Attribute msg
stopClick m =
    stopPropagationOn "click" (Decode.succeed ( m, True ))


stopPointerDown : Platform -> (PointerEvent -> msg) -> Attribute msg
stopPointerDown platform msg =
    stopPropagationOn "pointerdown" (pointerDecoder platform |> Decode.map (\e -> ( msg e, True )))



-- HELPERS


pointerDecoder : Platform -> Decode.Decoder PointerEvent
pointerDecoder platform =
    Decode.map6 PointerEvent
        (Decode.map2 Position
            (Decode.field "pageX" Decode.float)
            (Decode.field "pageY" Decode.float)
        )
        (Decode.field (B.cond (platform == Platform.Mac) "metaKey" "ctrlKey") Decode.bool)
        (Decode.field "altKey" Decode.bool)
        (Decode.field "shiftKey" Decode.bool)
        (Decode.field "metaKey" Decode.bool)
        (Decode.field "button" Decode.int |> Decode.map buttonFromId)


wheelDecoder : Platform -> Decode.Decoder WheelEvent
wheelDecoder platform =
    Decode.map6 WheelEvent
        (Decode.map2 Position
            (Decode.field "pageX" Decode.float)
            (Decode.field "pageY" Decode.float)
        )
        (Decode.map2 Delta
            (Decode.field "deltaX" Decode.float)
            (Decode.field "deltaY" Decode.float)
        )
        (Decode.field (B.cond (platform == Platform.Mac) "metaKey" "ctrlKey") Decode.bool)
        (Decode.field "altKey" Decode.bool)
        (Decode.field "shiftKey" Decode.bool)
        (Decode.field "metaKey" Decode.bool)


buttonFromId : Int -> Button
buttonFromId id =
    case id of
        0 ->
            Button.MainButton

        1 ->
            Button.MiddleButton

        2 ->
            Button.SecondButton

        3 ->
            Button.BackButton

        4 ->
            Button.ForwardButton

        _ ->
            Button.ErrorButton
