module Libs.Hotkey exposing (Hotkey, HotkeyTarget, hotkey, hotkeyEncoder, keys, target)

import Json.Encode as Encode exposing (Value)
import Libs.Bool as B
import Libs.Json.Encode as E


type alias Hotkey =
    { key : Maybe String, ctrl : Bool, shift : Bool, alt : Bool, meta : Bool, target : Maybe HotkeyTarget, onInput : Bool, preventDefault : Bool }


type alias HotkeyTarget =
    { id : Maybe String, class : Maybe String, tag : Maybe String }


hotkey : Hotkey
hotkey =
    { key = Nothing, ctrl = False, shift = False, alt = False, meta = False, target = Nothing, onInput = False, preventDefault = False }


target : HotkeyTarget
target =
    { id = Nothing, class = Nothing, tag = Nothing }


keys : Hotkey -> List String
keys h =
    [ B.cond h.ctrl (Just "Ctrl") Nothing
    , B.cond h.alt (Just "Alt") Nothing
    , B.cond h.shift (Just "Shift") Nothing
    , B.cond h.meta (Just "Meta") Nothing
    , h.key
    ]
        |> List.filterMap identity


hotkeyEncoder : Hotkey -> Value
hotkeyEncoder key =
    Encode.object
        [ ( "key", key.key |> E.maybe Encode.string )
        , ( "ctrl", key.ctrl |> Encode.bool )
        , ( "shift", key.shift |> Encode.bool )
        , ( "alt", key.alt |> Encode.bool )
        , ( "meta", key.meta |> Encode.bool )
        , ( "target", key.target |> E.maybe hotkeyTargetEncoder )
        , ( "onInput", key.onInput |> Encode.bool )
        , ( "preventDefault", key.preventDefault |> Encode.bool )
        ]


hotkeyTargetEncoder : HotkeyTarget -> Value
hotkeyTargetEncoder t =
    Encode.object
        [ ( "id", t.id |> E.maybe Encode.string )
        , ( "class", t.class |> E.maybe Encode.string )
        , ( "tag", t.tag |> E.maybe Encode.string )
        ]
