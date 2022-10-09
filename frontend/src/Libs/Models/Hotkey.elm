module Libs.Models.Hotkey exposing (Hotkey, HotkeyTarget, encode, hotkey, keys, target)

import Json.Encode as Encode exposing (Value)
import Libs.Bool as B
import Libs.Json.Encode as Encode
import Libs.Models.Platform as Platform exposing (Platform)


type alias Hotkey =
    { key : String, ctrl : Bool, shift : Bool, alt : Bool, target : Maybe HotkeyTarget, onInput : Bool, preventDefault : Bool }


type alias HotkeyTarget =
    { id : Maybe String, class : Maybe String, tag : Maybe String }


hotkey : Hotkey
hotkey =
    { key = "", ctrl = False, shift = False, alt = False, target = Nothing, onInput = False, preventDefault = False }


target : HotkeyTarget
target =
    { id = Nothing, class = Nothing, tag = Nothing }


keys : Platform -> Hotkey -> List String
keys platform h =
    [ B.cond h.ctrl (Just (B.cond (platform == Platform.Mac) "Cmd" "Ctrl")) Nothing
    , B.cond h.alt (Just "Alt") Nothing
    , B.cond h.shift (Just "Shift") Nothing
    , Just
        (case h.key of
            "ArrowUp" ->
                "↑"

            "ArrowDown" ->
                "↓"

            "ArrowLeft" ->
                "←"

            "ArrowRight" ->
                "→"

            _ ->
                h.key
        )
    ]
        |> List.filterMap identity


encode : Hotkey -> Value
encode key =
    Encode.object
        [ ( "key", key.key |> Encode.string )
        , ( "ctrl", key.ctrl |> Encode.bool )
        , ( "shift", key.shift |> Encode.bool )
        , ( "alt", key.alt |> Encode.bool )
        , ( "target", key.target |> Encode.maybe targetEncoder )
        , ( "onInput", key.onInput |> Encode.bool )
        , ( "preventDefault", key.preventDefault |> Encode.bool )
        ]


targetEncoder : HotkeyTarget -> Value
targetEncoder t =
    Encode.object
        [ ( "id", t.id |> Encode.maybe Encode.string )
        , ( "class", t.class |> Encode.maybe Encode.string )
        , ( "tag", t.tag |> Encode.maybe Encode.string )
        ]
