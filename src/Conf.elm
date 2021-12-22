module Conf exposing (SampleSchema, canvas, constants, hotkeys, ids, newsletter, schema, schemaSamples)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Slices.Newsletter as Newsletter
import Dict exposing (Dict)
import Libs.Hotkey exposing (Hotkey, hotkey, target)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.TwColor exposing (TwColor(..))
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Project.SchemaName exposing (SchemaName)


constants : { azimuttTwitter : String, azimuttGithub : String, azimuttEmail : String }
constants =
    { azimuttTwitter = "https://twitter.com/azimuttapp"
    , azimuttGithub = "https://github.com/azimuttapp/azimutt"
    , azimuttEmail = "hey@azimutt.app"
    }


newsletter : Newsletter.Form
newsletter =
    { method = "post", url = "https://www.getrevue.co/profile/azimuttapp/add_subscriber", placeholder = "Enter your email", cta = "Subscribe" }


type alias SampleSchema =
    { url : String, color : TwColor, icon : Icon, key : String, name : String, description : String, tables : Int }


schemaSamples : Dict String SampleSchema
schemaSamples =
    [ { url = "/samples/basic.sql", color = Pink, icon = ViewList, key = "basic", name = "Basic", description = "Simple login/role schema. The easiest one, just enough play with Azimutt features.", tables = 4 }
    , { url = "/samples/wordpress.sql", color = Yellow, icon = Template, key = "wordpress", name = "Wordpress", description = "The well known CMS powering most of the web. An interesting schema, but with no foreign keys!", tables = 12 }
    , { url = "/samples/gospeak.sql", color = Green, icon = ClipboardList, key = "gospeak", name = "Gospeak.io", description = "A full featured SaaS for meetup organizers. A good real world example to explore and really see the power of Azimutt.", tables = 26 }
    ]
        |> List.map (\sample -> ( sample.key, sample ))
        |> Dict.fromList


canvas :
    { zoom : { min : ZoomLevel, max : ZoomLevel, speed : Float }
    , zIndex : { tables : Int }
    , showAllTablesThreshold : Int
    }
canvas =
    { zoom = { min = 0.05, max = 5, speed = 0.001 }
    , zIndex = { tables = 10 }
    , showAllTablesThreshold = 20
    }


schema : { default : SchemaName }
schema =
    { default = "public" }


ids :
    { searchInput : HtmlId
    , navFeaturesDropdown : HtmlId
    , navProjectDropdown : HtmlId
    , navLayoutDropdown : HtmlId
    , menu : HtmlId
    , settings : HtmlId
    , erd : HtmlId
    , selectionBox : HtmlId
    , projectSwitchModal : HtmlId
    , findPathModal : HtmlId
    , newLayoutModal : HtmlId
    , helpModal : HtmlId
    , confirm : HtmlId
    }
ids =
    { searchInput = "search"
    , navFeaturesDropdown = "navbar-features-dropdown"
    , navProjectDropdown = "navbar-project-dropdown"
    , navLayoutDropdown = "navbar-layout-dropdown"
    , menu = "menu"
    , settings = "settings"
    , erd = "erd"
    , selectionBox = "selection-box"
    , projectSwitchModal = "project-switch-modal"
    , findPathModal = "find-path-modal"
    , newLayoutModal = "new-layout-modal"
    , helpModal = "help-modal"
    , confirm = "confirm-modal"
    }


hotkeys : Dict String (List Hotkey)
hotkeys =
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
        , ( "save-layout", [ { hotkey | key = Just "l", alt = True } ] )
        , ( "find-path", [ { hotkey | key = Just "p", alt = True } ] )
        , ( "create-virtual-relation", [ { hotkey | key = Just "v", alt = True } ] )
        , ( "undo", [ { hotkey | key = Just "z", ctrl = True } ] )
        , ( "redo", [ { hotkey | key = Just "Z", ctrl = True, shift = True } ] )
        , ( "cancel", [ { hotkey | key = Just "Escape" } ] )
        , ( "help", [ { hotkey | key = Just "?" } ] )
        ]
