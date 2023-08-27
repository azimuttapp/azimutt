module Conf exposing (Feature, Features, canvas, constants, features, hotkeys, ids, schema, ui)

import Dict exposing (Dict)
import Libs.Models.Hotkey exposing (Hotkey, hotkey, target)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Url as Url
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.SourceName exposing (SourceName)


constants :
    { azimuttWebsite : String
    , azimuttTwitter : String
    , azimuttGithub : String
    , azimuttDiscussions : String
    , azimuttRoadmap : String
    , azimuttBugReport : String
    , azimuttFeatureRequests : String
    , azimuttNewIssue : String -> String -> String
    , azimuttDiscussionFindPath : String
    , azimuttDiscussionSearch : String
    , azimuttDiscussionCanvas : String
    , azimuttEmail : String
    , defaultTitle : String
    , defaultDescription : String
    , newProjectName : ProjectName
    , defaultLayout : LayoutName
    , virtualRelationSourceName : SourceName
    , cheeringTweet : String
    , sharingTweet : String
    , canvasMargins : Float
    , manyTablesLimit : Int
    , fewTablesLimit : Int
    }
constants =
    { azimuttWebsite = "https://azimutt.app"
    , azimuttTwitter = "https://twitter.com/" ++ twitter
    , azimuttGithub = github
    , azimuttDiscussions = github ++ "/discussions"
    , azimuttRoadmap = github ++ "/projects/1"
    , azimuttBugReport = github ++ "/issues"
    , azimuttFeatureRequests = github ++ "/issues?q=is%3Aissue+is%3Aopen+label%3A%22feature+request%22"
    , azimuttNewIssue = \title body -> github ++ "/issues/new/?" ++ ([ ( "title", title ), ( "body", body ) ] |> List.filter (\( _, v ) -> v /= "") |> Url.buildQueryString)
    , azimuttDiscussionFindPath = github ++ "/discussions/7"
    , azimuttDiscussionSearch = github ++ "/discussions/8"
    , azimuttDiscussionCanvas = github ++ "/discussions/9"
    , azimuttEmail = "contact@azimutt.app"
    , defaultTitle = "Azimutt · Database explorer and analyzer"
    , defaultDescription = "Next-Gen ERD: Design, Explore, Document and Analyze your database."
    , newProjectName = "New Project"
    , defaultLayout = "initial layout"
    , virtualRelationSourceName = "default"
    , cheeringTweet = "Hi team, I really like what you've done with @" ++ twitter ++ ". Keep up the good work 💪"
    , sharingTweet = "Hi @" ++ twitter ++ ", I just published my schema at ..., I would love if you can share 🚀"
    , canvasMargins = 20
    , manyTablesLimit = 50
    , fewTablesLimit = 20
    }


twitter : String
twitter =
    "azimuttapp"


github : String
github =
    "https://github.com/azimuttapp/azimutt"


canvas :
    { zoom : { min : ZoomLevel, max : ZoomLevel, speed : Float }
    , zIndex : { tables : Int }
    , grid : Int
    }
canvas =
    { zoom = { min = 0.001, max = 5, speed = 0.001 }
    , zIndex = { tables = 10 }
    , grid = 10
    }


schema : { default : String, empty : String, column : { unknownType : String } }
schema =
    { default = "public"
    , empty = ""
    , column = { unknownType = "unknown" }
    }


ui :
    { openDuration : Int
    , closeDuration : Int
    , table : { headerHeight : Float, columnHeight : Float }
    , tableRow : { headerHeight : Float, columnHeight : Float }
    }
ui =
    { openDuration = 200
    , closeDuration = 300
    , table = { headerHeight = 45, columnHeight = 24 }
    , tableRow = { headerHeight = 34, columnHeight = 25 }
    }


type alias Features =
    { layouts : Feature Int
    , memos : Feature Int
    , groups : Feature Int
    , tableColor : Feature Bool
    , privateLinks : Feature Bool
    , sqlExport : Feature Bool
    , dbAnalysis : Feature Bool
    , dbAccess : Feature Bool
    }


type alias Feature a =
    { name : String, free : a }


features : Features
features =
    -- MUST stay in sync with backend/config/config.exs (`free_plan_layouts`)
    { layouts = { name = "layouts", free = 3 }
    , memos = { name = "memos", free = 5 }
    , groups = { name = "groups", free = 1 }
    , tableColor = { name = "table_color", free = False }
    , privateLinks = { name = "private_links", free = True }
    , sqlExport = { name = "sql_export", free = False }
    , dbAnalysis = { name = "analysis", free = False }
    , dbAccess = { name = "data_access", free = False }
    }


ids :
    { searchInput : HtmlId
    , sharingDialog : HtmlId
    , settingsDialog : HtmlId
    , sourceUpdateDialog : HtmlId
    , sourceParsingDialog : HtmlId
    , erd : HtmlId
    , selectionBox : HtmlId
    , editNotesDialog : HtmlId
    , amlSidebarDialog : HtmlId
    , detailsSidebarDialog : HtmlId
    , findPathDialog : HtmlId
    , dataExplorerDialog : HtmlId
    , schemaAnalysisDialog : HtmlId
    , helpDialog : HtmlId
    , customDialog : HtmlId
    , confirmDialog : HtmlId
    , promptDialog : HtmlId
    , modal : HtmlId
    }
ids =
    { searchInput = "app-nav-search"
    , sharingDialog = "sharing-dialog"
    , settingsDialog = "settings-dialog"
    , sourceUpdateDialog = "source-update-dialog"
    , sourceParsingDialog = "source-parsing-dialog"
    , erd = "erd"
    , selectionBox = "selection-box"
    , editNotesDialog = "edit-notes-dialog"
    , amlSidebarDialog = "aml-sidebar"
    , detailsSidebarDialog = "details-sidebar"
    , findPathDialog = "find-path-dialog"
    , dataExplorerDialog = "data-explorer-dialog"
    , schemaAnalysisDialog = "schema-analysis-dialog"
    , helpDialog = "help-dialog"
    , customDialog = "custom-dialog"
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
        , ( "notes", [ { hotkey | key = "n" } ] )
        , ( "new-memo", [ { hotkey | key = "m" } ] )
        , ( "create-group", [ { hotkey | key = "g" } ] )
        , ( "collapse", [ { hotkey | key = "c" } ] )
        , ( "expand", [ { hotkey | key = "ArrowRight", ctrl = True } ] )
        , ( "shrink", [ { hotkey | key = "ArrowLeft", ctrl = True } ] )
        , ( "show", [ { hotkey | key = "s" } ] )
        , ( "hide", [ { hotkey | key = "h" }, { hotkey | key = "Backspace" }, { hotkey | key = "Delete" } ] )
        , ( "save", [ { hotkey | key = "s", ctrl = True, onInput = True, preventDefault = True } ] )
        , ( "move-up", [ { hotkey | key = "ArrowUp" } ] )
        , ( "move-right", [ { hotkey | key = "ArrowRight" } ] )
        , ( "move-down", [ { hotkey | key = "ArrowDown" } ] )
        , ( "move-left", [ { hotkey | key = "ArrowLeft" } ] )
        , ( "move-forward", [ { hotkey | key = "ArrowUp", ctrl = True } ] )
        , ( "move-backward", [ { hotkey | key = "ArrowDown", ctrl = True } ] )
        , ( "move-to-top", [ { hotkey | key = "ArrowUp", ctrl = True, shift = True } ] )
        , ( "move-to-back", [ { hotkey | key = "ArrowDown", ctrl = True, shift = True } ] )
        , ( "select-all", [ { hotkey | key = "a", ctrl = True, preventDefault = True } ] )
        , ( "create-layout", [ { hotkey | key = "l", alt = True } ] )
        , ( "create-virtual-relation", [ { hotkey | key = "v", alt = True } ] )
        , ( "find-path", [ { hotkey | key = "p", alt = True } ] )
        , ( "reset-zoom", [ { hotkey | key = "0", ctrl = True } ] )
        , ( "fit-to-screen", [ { hotkey | key = "0", ctrl = True, alt = True } ] )
        , ( "undo", [ { hotkey | key = "z", ctrl = True } ] )
        , ( "redo", [ { hotkey | key = "Z", ctrl = True, shift = True } ] )
        , ( "cancel", [ { hotkey | key = "Escape" } ] )
        , ( "help", [ { hotkey | key = "?" } ] )
        ]
