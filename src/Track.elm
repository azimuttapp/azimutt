module Track exposing (SQLParsing, addSource, createLayout, createProject, deleteLayout, deleteProject, externalLink, findPathResult, loadLayout, loadProject, openAppCta, openFindPath, openHelp, openIncomingRelationsDropdown, openSaveLayout, openSettings, openTableSettings, parsedSource, refreshSource, showTableWithForeignKey, showTableWithIncomingRelationsDropdown, updateLayout, updateProject)

import DataSources.SqlParser.FileParser exposing (SchemaError)
import DataSources.SqlParser.StatementParser exposing (Command)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlStatement)
import Dict exposing (Dict)
import Libs.Dict as D
import Libs.Maybe as M
import Libs.Models exposing (FileLineContent, TrackEvent)
import Libs.Result as R
import Models.Project exposing (Project)
import Models.Project.FindPathResult exposing (FindPathResult)
import Models.Project.Layout exposing (Layout)
import Models.Project.Source exposing (Source)



-- all tracking events should be declared here to have a good overview of them


openAppCta : String -> TrackEvent
openAppCta source =
    { name = "open-app-cta", details = [ ( "source", source ) ], enabled = True }


openSettings : TrackEvent
openSettings =
    { name = "open-settings", details = [], enabled = True }


openHelp : TrackEvent
openHelp =
    { name = "open-help", details = [], enabled = True }


openTableSettings : TrackEvent
openTableSettings =
    { name = "open-table-settings", details = [], enabled = True }


showTableWithForeignKey : TrackEvent
showTableWithForeignKey =
    { name = "show-table-with-foreign-key", details = [], enabled = True }


showTableWithIncomingRelationsDropdown : TrackEvent
showTableWithIncomingRelationsDropdown =
    { name = "show-table-with-incoming-relations-dropdown", details = [], enabled = True }


openIncomingRelationsDropdown : TrackEvent
openIncomingRelationsDropdown =
    { name = "open-incoming-relations-dropdown", details = [], enabled = True }


openSaveLayout : TrackEvent
openSaveLayout =
    { name = "open-save-layout", details = [], enabled = True }


parsedSource : SQLParsing msg -> Source -> TrackEvent
parsedSource =
    parseSQLEvent


createProject : Project -> TrackEvent
createProject =
    projectEvent "create"


loadProject : Project -> TrackEvent
loadProject =
    projectEvent "load"


updateProject : Project -> TrackEvent
updateProject =
    projectEvent "update"


deleteProject : Project -> TrackEvent
deleteProject =
    projectEvent "delete"


addSource : Source -> TrackEvent
addSource =
    sourceEvent "add"


refreshSource : Source -> TrackEvent
refreshSource =
    sourceEvent "refresh"


createLayout : Layout -> TrackEvent
createLayout =
    layoutEvent "create"


loadLayout : Layout -> TrackEvent
loadLayout =
    layoutEvent "load"


updateLayout : Layout -> TrackEvent
updateLayout =
    layoutEvent "update"


deleteLayout : Layout -> TrackEvent
deleteLayout =
    layoutEvent "delete"


externalLink : String -> TrackEvent
externalLink url =
    { name = "external-link", details = [ ( "url", url ) ], enabled = True }


openFindPath : TrackEvent
openFindPath =
    { name = "open-find-path", details = [], enabled = True }


findPathResult : FindPathResult -> TrackEvent
findPathResult =
    findPathResults



-- HELPERS


type alias SQLParsing x =
    { x
        | lines : Maybe (List FileLineContent)
        , statements : Maybe (Dict Int SqlStatement)
        , commands : Maybe (Dict Int ( SqlStatement, Result (List ParseError) Command ))
        , schemaErrors : List (List SchemaError)
    }


parseSQLEvent : SQLParsing msg -> Source -> TrackEvent
parseSQLEvent parser source =
    { name = "parse" ++ (source.fromSample |> M.mapOrElse (\_ -> "-sample") "") ++ "-sql-source"
    , details =
        [ ( "lines-count", parser.lines |> M.mapOrElse List.length 0 |> String.fromInt )
        , ( "statements-count", parser.statements |> M.mapOrElse Dict.size 0 |> String.fromInt )
        , ( "table-count", source.tables |> Dict.size |> String.fromInt )
        , ( "relation-count", source.relations |> List.length |> String.fromInt )
        , ( "parsing-errors", parser.commands |> M.mapOrElse (D.count (\_ ( _, r ) -> r |> R.isErr)) 0 |> String.fromInt )
        , ( "schema-errors", parser.schemaErrors |> List.length |> String.fromInt )
        ]
    , enabled = True
    }


projectEvent : String -> Project -> TrackEvent
projectEvent eventName project =
    { name = eventName ++ (project.sources |> List.concatMap (.fromSample >> M.toList) |> List.head |> M.mapOrElse (\_ -> "-sample") "") ++ "-project"
    , details =
        [ ( "table-count", project.tables |> Dict.size |> String.fromInt )
        , ( "relation-count", project.relations |> List.length |> String.fromInt )
        , ( "layout-count", project.layouts |> Dict.size |> String.fromInt )
        ]
    , enabled = True
    }


sourceEvent : String -> Source -> TrackEvent
sourceEvent eventName source =
    { name = eventName ++ "-source"
    , details =
        [ ( "table-count", source.tables |> Dict.size |> String.fromInt )
        , ( "relation-count", source.relations |> List.length |> String.fromInt )
        ]
    , enabled = True
    }


layoutEvent : String -> Layout -> TrackEvent
layoutEvent eventName layout =
    { name = eventName ++ "-layout", details = [ ( "table-count", layout.tables |> List.length |> String.fromInt ) ], enabled = True }


findPathResults : FindPathResult -> TrackEvent
findPathResults result =
    { name = "find-path-results"
    , details =
        [ ( "found-paths", String.fromInt (result.paths |> List.length) )
        , ( "ignored-columns", String.fromInt (result.settings.ignoredColumns |> List.length) )
        , ( "ignored-tables", String.fromInt (result.settings.ignoredTables |> List.length) )
        , ( "max-path-length", String.fromInt result.settings.maxPathLength )
        ]
    , enabled = True
    }
