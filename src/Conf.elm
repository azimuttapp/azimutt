module Conf exposing (conf, constants, newsletterConf, schemaSamples)

import Components.Slices.Newsletter as Newsletter
import Dict exposing (Dict)
import Libs.Hotkey exposing (Hotkey, hotkey, target)
import Libs.Models exposing (Color, FileUrl, HtmlId, ZoomLevel)


conf :
    { zoom : { min : ZoomLevel, max : ZoomLevel, speed : Float }
    , colors : List Color
    , default : { schema : String, color : Color }
    , zIndex : { tables : Int }
    , ids :
        { searchInput : HtmlId
        , navFeaturesDropdown : HtmlId
        , navProjectDropdown : HtmlId
        , navLayoutDropdown : HtmlId
        , menu : HtmlId
        , settings : HtmlId
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
        , navFeaturesDropdown = "navbar-features-dropdown"
        , navProjectDropdown = "navbar-project-dropdown"
        , navLayoutDropdown = "navbar-layout-dropdown"
        , menu = "menu"
        , settings = "settings"
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
            , ( "select-all", [ { hotkey | key = Just "a", ctrl = True, preventDefault = True } ] )
            , ( "find-path", [ { hotkey | key = Just "p", alt = True } ] )
            , ( "create-virtual-relation", [ { hotkey | key = Just "v", alt = True } ] )
            , ( "undo", [ { hotkey | key = Just "z", ctrl = True } ] )
            , ( "redo", [ { hotkey | key = Just "Z", ctrl = True, shift = True } ] )
            , ( "cancel", [ { hotkey | key = Just "Escape" } ] )
            , ( "help", [ { hotkey | key = Just "?" } ] )
            ]
    }


constants : { azimuttTwitter : String, azimuttGithub : String }
constants =
    { azimuttTwitter = "https://twitter.com/azimuttapp"
    , azimuttGithub = "https://github.com/azimuttapp/azimutt"
    }


newsletterConf : Newsletter.Form
newsletterConf =
    { method = "post", url = "https://www.getrevue.co/profile/azimuttapp/add_subscriber", placeholder = "Enter your email", cta = "Subscribe" }


schemaSamples : Dict String ( Int, FileUrl )
schemaSamples =
    Dict.fromList
        [ ( "basic schema", ( 4, "samples/basic.json" ) )
        , ( "wordpress", ( 12, "samples/wordpress.sql" ) )
        , ( "gospeak.io", ( 26, "samples/gospeak.sql" ) )
        ]
