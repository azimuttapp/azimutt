module Libs.Html.Events exposing (PointerEvent, WheelEvent, onContextMenu, onDblClick, onPointerDown, onPointerUp, onWheel, pointerDecoder, wheelDecoder)

import Html exposing (Attribute)
import Html.Events
import Html.Events.Extra.Mouse as Button exposing (Button)
import Json.Decode as Decode
import Libs.Bool as B
import Libs.Models.Delta as Delta exposing (Delta)
import Libs.Models.Platform as Platform exposing (Platform)
import Models.Position as Position



-- sorted alphabetically


type alias PointerEvent =
    { clientPos : Position.Viewport
    , pagePos : Position.Document
    , ctrl : Bool
    , alt : Bool
    , shift : Bool
    , meta : Bool
    , button : Button
    }


onContextMenu : (PointerEvent -> msg) -> Platform -> Attribute msg
onContextMenu toMsg platform =
    Html.Events.custom "contextmenu" (pointerDecoder platform |> Decode.map (\e -> { message = toMsg e, stopPropagation = True, preventDefault = True }))


onPointerUp : (PointerEvent -> msg) -> Platform -> Attribute msg
onPointerUp toMsg platform =
    Html.Events.custom "pointerup" (pointerDecoder platform |> Decode.map (\e -> { message = toMsg e, stopPropagation = True, preventDefault = False }))


onPointerDown : (PointerEvent -> msg) -> Platform -> Attribute msg
onPointerDown toMsg platform =
    Html.Events.custom "pointerdown" (pointerDecoder platform |> Decode.map (\e -> { message = toMsg e, stopPropagation = True, preventDefault = False }))


onDblClick : (PointerEvent -> msg) -> Platform -> Attribute msg
onDblClick toMsg platform =
    Html.Events.custom "dblclick" (pointerDecoder platform |> Decode.map (\e -> { message = toMsg e, stopPropagation = True, preventDefault = False }))


type alias FileEvent =
    { inputId : String, file : List FileInfo }


type alias FileInfo =
    { name : String, kind : String, size : Int, lastModified : Int }


onFileChange : (FileEvent -> msg) -> Attribute msg
onFileChange toMsg =
    -- Elm: no error message when decoder fail, hard to get it correct :(
    let
        fileDecoder : Decode.Decoder FileInfo
        fileDecoder =
            Decode.map4 FileInfo
                (Decode.field "name" Decode.string)
                (Decode.field "type" Decode.string)
                (Decode.field "size" Decode.int)
                (Decode.field "lastModified" Decode.int)

        decoder : Decode.Decoder FileEvent
        decoder =
            Decode.field "target"
                (Decode.map2 FileEvent
                    (Decode.field "id" Decode.string)
                    (Decode.field "files" (Decode.list fileDecoder))
                )
    in
    Html.Events.custom "change" (decoder |> Decode.map (\e -> { message = toMsg e, stopPropagation = True, preventDefault = False }))


type alias WheelEvent =
    { clientPos : Position.Viewport
    , pagePos : Position.Document
    , delta : Delta
    , ctrl : Bool
    , alt : Bool
    , shift : Bool
    , meta : Bool
    }


onWheel : (WheelEvent -> msg) -> Platform -> Attribute msg
onWheel toMsg platform =
    Html.Events.custom "wheel" (wheelDecoder platform |> Decode.map (\e -> { message = toMsg e, stopPropagation = True, preventDefault = True }))



-- HELPERS


pointerDecoder : Platform -> Decode.Decoder PointerEvent
pointerDecoder platform =
    Decode.map7 PointerEvent
        Position.decodeViewport
        Position.decodeDocument
        (Decode.field (B.cond (platform == Platform.Mac) "metaKey" "ctrlKey") Decode.bool)
        (Decode.field "altKey" Decode.bool)
        (Decode.field "shiftKey" Decode.bool)
        (Decode.field "metaKey" Decode.bool)
        (Decode.field "button" Decode.int |> Decode.map buttonFromId)


wheelDecoder : Platform -> Decode.Decoder WheelEvent
wheelDecoder platform =
    Decode.map7 WheelEvent
        Position.decodeViewport
        Position.decodeDocument
        Delta.decodeEvent
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
