module Conf exposing (conf, schemaSamples)

import Dict exposing (Dict)
import Libs.Hotkey exposing (Hotkey, hotkey, target)
import Libs.Models exposing (Color, HtmlId, ZoomLevel)


conf :
    { zoom : { min : ZoomLevel, max : ZoomLevel, speed : Float }
    , colors : List Color
    , default : { schema : String, color : Color }
    , zIndex : { tables : Int }
    , ids :
        { searchInput : HtmlId
        , menu : HtmlId
        , erd : HtmlId
        , projectSwitchModal : HtmlId
        , findPathModal : HtmlId
        , newLayoutModal : HtmlId
        , helpModal : HtmlId
        , confirm : HtmlId
        }
    , loading : { showTablesThreshold : Int }
    , hotkeys : Dict String (List Hotkey)
    }
conf =
    { zoom = { min = 0.05, max = 5, speed = 0.001 }
    , colors = [ "red", "orange", "amber", "yellow", "lime", "green", "emerald", "teal", "cyan", "sky", "blue", "indigo", "violet", "purple", "fuchsia", "pink", "rose" ]
    , default = { schema = "public", color = "gray" }
    , zIndex = { tables = 10 }
    , ids =
        { searchInput = "search"
        , menu = "menu"
        , erd = "erd"
        , projectSwitchModal = "project-switch-modal"
        , findPathModal = "find-path-modal"
        , newLayoutModal = "new-layout-modal"
        , helpModal = "help-modal"
        , confirm = "confirm-modal"
        }
    , loading = { showTablesThreshold = 20 }
    , hotkeys =
        Dict.fromList
            [ ( "focus-search", [ { hotkey | key = Just "/" } ] )
            , ( "autocomplete-up", [ { hotkey | key = Just "ArrowUp", target = Just { target | id = Just "search", tag = Just "input" } } ] )
            , ( "autocomplete-down", [ { hotkey | key = Just "ArrowDown", target = Just { target | id = Just "search", tag = Just "input" } } ] )
            , ( "remove", [ { hotkey | key = Just "d" }, { hotkey | key = Just "h" }, { hotkey | key = Just "Backspace" }, { hotkey | key = Just "Delete" } ] )
            , ( "save", [ { hotkey | key = Just "s", ctrl = True, onInput = True, preventDefault = True } ] )
            , ( "move-forward", [ { hotkey | key = Just "ArrowUp", ctrl = True } ] )
            , ( "move-backward", [ { hotkey | key = Just "ArrowDown", ctrl = True } ] )
            , ( "move-to-top", [ { hotkey | key = Just "ArrowUp", ctrl = True, shift = True } ] )
            , ( "move-to-back", [ { hotkey | key = Just "ArrowDown", ctrl = True, shift = True } ] )
            , ( "undo", [ { hotkey | key = Just "z", ctrl = True } ] )
            , ( "redo", [ { hotkey | key = Just "Z", ctrl = True, shift = True } ] )
            , ( "help", [ { hotkey | key = Just "?" } ] )
            ]
    }


schemaSamples : Dict String ( Int, String )
schemaSamples =
    Dict.fromList
        [ ( "basic schema", ( 4, "samples/basic.json" ) )
        , ( "wordpress", ( 12, "samples/wordpress.sql" ) )
        , ( "gospeak.io", ( 26, "samples/gospeak.sql" ) )
        ]
