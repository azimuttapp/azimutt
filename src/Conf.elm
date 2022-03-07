module Conf exposing (SampleSchema, blogPosts, canvas, constants, hotkeys, ids, newsletter, schema, schemaSamples, ui)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Slices.Newsletter as Newsletter
import Dict exposing (Dict)
import Libs.Hotkey exposing (Hotkey, hotkey, target)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Tailwind as Tw exposing (Color)
import Models.Project.SchemaName exposing (SchemaName)


constants :
    { azimuttTwitter : String
    , azimuttGithub : String
    , azimuttDiscussions : String
    , azimuttRoadmap : String
    , azimuttBugReport : String
    , azimuttFeatureRequests : String
    , azimuttDiscussionFindPath : String
    , azimuttDiscussionSearch : String
    , azimuttDiscussionCanvas : String
    , azimuttEmail : String
    , cheeringTweet : String
    }
constants =
    { azimuttTwitter = "https://twitter.com/" ++ twitter
    , azimuttGithub = github
    , azimuttDiscussions = github ++ "/discussions"
    , azimuttRoadmap = github ++ "/projects/1"
    , azimuttBugReport = github ++ "/issues"
    , azimuttFeatureRequests = github ++ "/issues?q=is%3Aissue+is%3Aopen+label%3A%22feature+request%22"
    , azimuttDiscussionFindPath = github ++ "/discussions/7"
    , azimuttDiscussionSearch = github ++ "/discussions/8"
    , azimuttDiscussionCanvas = github ++ "/discussions/9"
    , azimuttEmail = "hey@azimutt.app"
    , cheeringTweet = "Hi team, I really like what you've done with @" ++ twitter ++ ". Keep up the good work 💪"
    }


twitter : String
twitter =
    "azimuttapp"


github : String
github =
    "https://github.com/azimuttapp/azimutt"


newsletter : Newsletter.Form
newsletter =
    { method = "post", url = "https://www.getrevue.co/profile/azimuttapp/add_subscriber", placeholder = "Enter your email", cta = "Subscribe" }


type alias SampleSchema =
    { url : String, color : Color, icon : Icon, key : String, name : String, description : String, tables : Int }


schemaSamples : Dict String SampleSchema
schemaSamples =
    [ { url = "/samples/basic.azimutt.json", color = Tw.pink, icon = ViewList, key = "basic", name = "Basic", description = "Simple login/role schema. The easiest one, just enough play with Azimutt features.", tables = 4 }
    , { url = "/samples/wordpress.azimutt.json", color = Tw.yellow, icon = Template, key = "wordpress", name = "Wordpress", description = "The well known CMS powering most of the web. An interesting schema, but with no foreign keys!", tables = 12 }
    , { url = "/samples/gospeak.azimutt.json", color = Tw.green, icon = ClipboardList, key = "gospeak", name = "Gospeak.io", description = "A full featured SaaS for meetup organizers. A good real world example to explore and really see the power of Azimutt.", tables = 26 }
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


ui : { openDuration : Int, closeDuration : Int, tableHeaderHeight : Float, tableColumnHeight : Float }
ui =
    { openDuration = 200, closeDuration = 300, tableHeaderHeight = 45, tableColumnHeight = 24 }


ids :
    { searchInput : HtmlId
    , settingsDialog : HtmlId
    , sourceUploadDialog : HtmlId
    , erd : HtmlId
    , selectionBox : HtmlId
    , newLayoutDialog : HtmlId
    , findPathDialog : HtmlId
    , schemaAnalysisDialog : HtmlId
    , helpDialog : HtmlId
    , confirmDialog : HtmlId
    , promptDialog : HtmlId
    , modal : HtmlId
    }
ids =
    { searchInput = "app-nav-search"
    , settingsDialog = "settings-dialog"
    , sourceUploadDialog = "source-upload-dialog"
    , erd = "erd"
    , selectionBox = "selection-box"
    , newLayoutDialog = "new-layout-dialog"
    , findPathDialog = "find-path-dialog"
    , schemaAnalysisDialog = "schema-analysis-dialog"
    , helpDialog = "help-dialog"
    , confirmDialog = "confirm-dialog"
    , promptDialog = "prompt-dialog"
    , modal = "modal"
    }


hotkeys : Dict String (List Hotkey)
hotkeys =
    Dict.fromList
        [ ( "search-open", [ { hotkey | key = "/" } ] )
        , ( "search-up", [ { hotkey | key = "ArrowUp", target = Just { target | tag = Just "input", id = Just ids.searchInput } } ] )
        , ( "search-down", [ { hotkey | key = "ArrowDown", target = Just { target | tag = Just "input", id = Just ids.searchInput } } ] )
        , ( "search-confirm", [ { hotkey | key = "Enter", target = Just { target | tag = Just "input", id = Just ids.searchInput } } ] )
        , ( "remove", [ { hotkey | key = "d" }, { hotkey | key = "Backspace" }, { hotkey | key = "Delete" } ] )
        , ( "save", [ { hotkey | key = "s", ctrl = True, onInput = True, preventDefault = True } ] )
        , ( "move-up", [ { hotkey | key = "ArrowUp" } ] )
        , ( "move-right", [ { hotkey | key = "ArrowRight" } ] )
        , ( "move-down", [ { hotkey | key = "ArrowDown" } ] )
        , ( "move-left", [ { hotkey | key = "ArrowLeft" } ] )
        , ( "move-up-big", [ { hotkey | key = "ArrowUp", shift = True } ] )
        , ( "move-right-big", [ { hotkey | key = "ArrowRight", shift = True } ] )
        , ( "move-down-big", [ { hotkey | key = "ArrowDown", shift = True } ] )
        , ( "move-left-big", [ { hotkey | key = "ArrowLeft", shift = True } ] )
        , ( "move-forward", [ { hotkey | key = "ArrowUp", ctrl = True } ] )
        , ( "move-backward", [ { hotkey | key = "ArrowDown", ctrl = True } ] )
        , ( "move-to-top", [ { hotkey | key = "ArrowUp", ctrl = True, shift = True } ] )
        , ( "move-to-back", [ { hotkey | key = "ArrowDown", ctrl = True, shift = True } ] )
        , ( "select-all", [ { hotkey | key = "a", ctrl = True, preventDefault = True } ] )
        , ( "save-layout", [ { hotkey | key = "l", alt = True } ] )
        , ( "create-virtual-relation", [ { hotkey | key = "v", alt = True } ] )
        , ( "find-path", [ { hotkey | key = "p", alt = True } ] )
        , ( "reset-zoom", [ { hotkey | key = "0", ctrl = True } ] )
        , ( "fit-to-screen", [ { hotkey | key = "0", ctrl = True, alt = True } ] )
        , ( "undo", [ { hotkey | key = "z", ctrl = True } ] )
        , ( "redo", [ { hotkey | key = "Z", ctrl = True, shift = True } ] )
        , ( "cancel", [ { hotkey | key = "Escape" } ] )
        , ( "help", [ { hotkey | key = "?" } ] )
        ]


blogPosts : List String
blogPosts =
    [ "the-story-behind-azimutt"
    , "how-to-explore-your-database-schema-with-azimutt"
    , "why-you-should-avoid-tables-with-many-columns-and-how-to-fix-them"

    --, "azimutt-analyze-your-database-schema-so-you-can-improve-it"
    --, "entity-relationship-diagram-landscape-how-to-choose"
    ]
