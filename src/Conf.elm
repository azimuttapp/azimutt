module Conf exposing (SampleSchema, blogPosts, canvas, constants, hotkeys, ids, newsletter, schema, schemaSamples, ui)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Slices.Newsletter as Newsletter
import Dict exposing (Dict)
import Libs.Hotkey exposing (Hotkey, hotkey, target)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Tailwind as Tw exposing (Color)
import Libs.Url as Url
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.SchemaName exposing (SchemaName)
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
    , cheeringTweet : String
    , sharingTweet : String
    , defaultLayout : LayoutName
    , virtualRelationSourceName : SourceName
    , externalAssets : String
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
    , azimuttEmail = "hey@azimutt.app"
    , defaultTitle = "Azimutt - Database explorer and analyzer"
    , defaultDescription = "Next gen ERD: explore and analyze your SQL database schema. Search and display what you want, follow relations, find paths and much more..."
    , cheeringTweet = "Hi team, I really like what you've done with @" ++ twitter ++ ". Keep up the good work 💪"
    , sharingTweet = "Hi @" ++ twitter ++ ", I just published my schema at ..., I would love if you can share 🚀"
    , defaultLayout = "initial layout"
    , virtualRelationSourceName = "default"
    , externalAssets = "https://xkwctrduvpdgjarqzjkc.supabase.co/storage/v1/object/public/assets"
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
    , { url = "/samples/gladys.azimutt.json", color = Tw.cyan, icon = Home, key = "gladys", name = "Gladys Assistant", description = "A privacy-first, open-source home assistant with many features and integrations", tables = 21 }
    , { url = "/samples/gospeak.azimutt.json", color = Tw.purple, icon = ClipboardList, key = "gospeak", name = "Gospeak.io", description = "SaaS for meetup organizers. Good real world example to explore and see the power of Azimutt.", tables = 26 }
    ]
        |> List.map (\sample -> ( sample.key, sample ))
        |> Dict.fromList


canvas :
    { zoom : { min : ZoomLevel, max : ZoomLevel, speed : Float }
    , zIndex : { tables : Int }
    , grid : Int
    }
canvas =
    { zoom = { min = 0.05, max = 5, speed = 0.001 }
    , zIndex = { tables = 10 }
    , grid = 10
    }


schema : { default : SchemaName, column : { unknownType : ColumnType } }
schema =
    { default = "public"
    , column = { unknownType = "unknown" }
    }


ui :
    { openDuration : Int
    , closeDuration : Int
    , navbarHeight : Float
    , tableHeaderHeight : Float
    , tableColumnHeight : Float
    }
ui =
    { openDuration = 200
    , closeDuration = 300
    , navbarHeight = 64
    , tableHeaderHeight = 45
    , tableColumnHeight = 24
    }


ids :
    { searchInput : HtmlId
    , sharingDialog : HtmlId
    , settingsDialog : HtmlId
    , sourceUpdateDialog : HtmlId
    , sourceParsingDialog : HtmlId
    , erd : HtmlId
    , selectionBox : HtmlId
    , newLayoutDialog : HtmlId
    , editNotesDialog : HtmlId
    , amlSidebarDialog : HtmlId
    , findPathDialog : HtmlId
    , schemaAnalysisDialog : HtmlId
    , helpDialog : HtmlId
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
    , newLayoutDialog = "new-layout-dialog"
    , editNotesDialog = "edit-notes-dialog"
    , amlSidebarDialog = "aml-sidebar"
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
        , ( "notes", [ { hotkey | key = "n" } ] )
        , ( "collapse", [ { hotkey | key = "c" } ] )
        , ( "expand", [ { hotkey | key = "ArrowRight", ctrl = True } ] )
        , ( "shrink", [ { hotkey | key = "ArrowLeft", ctrl = True } ] )
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


blogPosts : List String
blogPosts =
    [ "the-story-behind-azimutt"
    , "how-to-explore-your-database-schema-with-azimutt"
    , "why-you-should-avoid-tables-with-many-columns-and-how-to-fix-them"
    , "embed-your-database-diagram-anywhere"
    , "how-to-choose-your-entity-relationship-diagram"
    , "improve-your-database-design-with-azimutt-analyzer"
    , "aml-a-language-to-define-your-database-schema"
    , "stop-using-auto-increment-for-primary-keys"
    , "changelog-2022-06"

    --, "make-your-app-hackable"
    ]
