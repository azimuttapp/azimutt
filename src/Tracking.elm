module Tracking exposing (events)

import Dict
import Libs.Models exposing (TrackEvent)
import Models.Project exposing (FindPathResult, Layout, Project)


events :
    { openAppCta : String -> TrackEvent
    , openMenu : TrackEvent
    , openHelp : TrackEvent
    , openTableSettings : TrackEvent
    , showTableWithForeignKey : TrackEvent
    , showTableWithIncomingRelationsDropdown : TrackEvent
    , openIncomingRelationsDropdown : TrackEvent
    , openSaveLayout : TrackEvent
    , openFindPath : TrackEvent
    , findPathResult : FindPathResult -> TrackEvent
    , createProject : Project -> TrackEvent
    , loadProject : Project -> TrackEvent
    , updateProject : Project -> TrackEvent
    , deleteProject : Project -> TrackEvent
    , createLayout : Layout -> TrackEvent
    , loadLayout : Layout -> TrackEvent
    , updateLayout : Layout -> TrackEvent
    , deleteLayout : Layout -> TrackEvent
    }
events =
    { openAppCta = openAppCta
    , openMenu = { name = "open-menu", details = [] }
    , openHelp = { name = "open-help", details = [] }
    , openTableSettings = { name = "open-table-settings", details = [] }
    , showTableWithForeignKey = { name = "show-table-with-foreign-key", details = [] }
    , showTableWithIncomingRelationsDropdown = { name = "show-table-with-incoming-relations-dropdown", details = [] }
    , openIncomingRelationsDropdown = { name = "open-incoming-relations-dropdown", details = [] }
    , openSaveLayout = { name = "open-save-layout", details = [] }
    , openFindPath = { name = "open-find-path", details = [] }
    , findPathResult = findPathResults
    , createProject = projectEvent "create"
    , loadProject = projectEvent "load"
    , updateProject = projectEvent "update"
    , deleteProject = projectEvent "delete"
    , createLayout = layoutEvent "create"
    , loadLayout = layoutEvent "load"
    , updateLayout = layoutEvent "update"
    , deleteLayout = layoutEvent "delete"
    }


openAppCta : String -> TrackEvent
openAppCta source =
    { name = "open-app-cta", details = [ ( "source", source ) ] }


findPathResults : FindPathResult -> TrackEvent
findPathResults result =
    { name = "find-path-results"
    , details =
        [ ( "found-paths", String.fromInt (result.paths |> List.length) )
        , ( "ignored-columns", String.fromInt (result.settings.ignoredColumns |> List.length) )
        , ( "ignored-tables", String.fromInt (result.settings.ignoredTables |> List.length) )
        , ( "max-path-length", String.fromInt result.settings.maxPathLength )
        ]
    }


projectEvent : String -> Project -> TrackEvent
projectEvent eventName project =
    { name = eventName ++ (project.fromSample |> Maybe.map (\_ -> "-sample") |> Maybe.withDefault "") ++ "-project"
    , details =
        [ ( "table-count", project.schema.tables |> Dict.size |> String.fromInt )
        , ( "layout-count", project.layouts |> Dict.size |> String.fromInt )
        ]
    }


layoutEvent : String -> Layout -> TrackEvent
layoutEvent eventName layout =
    { name = eventName ++ "-layout", details = [ ( "table-count", layout.tables |> List.length |> String.fromInt ) ] }
