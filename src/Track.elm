module Track exposing (SQLParsing, addSource, createLayout, createProject, deleteLayout, deleteProject, externalLink, findPathResult, importProject, loadLayout, loadProject, notFoundLayout, openAppCta, openEditNotes, openFindPath, openHelp, openIncomingRelationsDropdown, openProjectUploadDialog, openSaveLayout, openSchemaAnalysis, openSettings, openSharing, openTableSettings, openUserSourceUpdate, parsedSource, refreshSource, showTableWithForeignKey, showTableWithIncomingRelationsDropdown, updateLayout, updateProject)

import DataSources.Helpers exposing (SourceLine)
import DataSources.SqlParser.SqlAdapter exposing (SqlSchema)
import DataSources.SqlParser.SqlParser exposing (Command)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlStatement)
import Dict exposing (Dict)
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Models exposing (TrackEvent)
import Libs.Result as Result
import Models.Project exposing (Project)
import Models.Project.Layout exposing (Layout)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectId as ProjectId
import Models.Project.Source exposing (Source)
import PagesComponents.Projects.Id_.Models.FindPathResult exposing (FindPathResult)
import PagesComponents.Projects.Id_.Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)



-- all tracking events should be declared here to have a good overview of them


openAppCta : String -> TrackEvent
openAppCta source =
    { name = "open-app-cta", details = [ ( "source", source ) ], enabled = True }


openProjectUploadDialog : TrackEvent
openProjectUploadDialog =
    { name = "open-project-upload-dialog", details = [], enabled = True }


openSharing : TrackEvent
openSharing =
    { name = "open-sharing", details = [], enabled = True }


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


openEditNotes : TrackEvent
openEditNotes =
    { name = "open-edit-notes", details = [], enabled = True }


openUserSourceUpdate : TrackEvent
openUserSourceUpdate =
    { name = "open-user-source-update", details = [], enabled = True }


parsedSource : SQLParsing msg -> Source -> TrackEvent
parsedSource =
    parseSQLEvent


createProject : Project -> TrackEvent
createProject project =
    projectEvent "create" (ProjectInfo.create project)


importProject : Project -> TrackEvent
importProject project =
    projectEvent "import" (ProjectInfo.create project)


loadProject : ProjectInfo -> TrackEvent
loadProject =
    projectEvent "load"


updateProject : Project -> TrackEvent
updateProject project =
    projectEvent "update" (ProjectInfo.create project)


deleteProject : ProjectInfo -> TrackEvent
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


notFoundLayout : LayoutName -> TrackEvent
notFoundLayout _ =
    { name = "not-found-layout", details = [], enabled = True }


externalLink : String -> TrackEvent
externalLink url =
    { name = "external-link", details = [ ( "url", url ) ], enabled = True }


openFindPath : TrackEvent
openFindPath =
    { name = "open-find-path", details = [], enabled = True }


openSchemaAnalysis : TrackEvent
openSchemaAnalysis =
    { name = "open-schema-analysis", details = [], enabled = True }


findPathResult : FindPathResult -> TrackEvent
findPathResult =
    findPathResults



-- HELPERS


type alias SQLParsing x =
    { x
        | lines : Maybe (List SourceLine)
        , statements : Maybe (Dict Int SqlStatement)
        , commands : Maybe (Dict Int ( SqlStatement, Result (List ParseError) Command ))
        , schema : Maybe SqlSchema
    }


parseSQLEvent : SQLParsing msg -> Source -> TrackEvent
parseSQLEvent parser source =
    { name = "parse" ++ (source.fromSample |> Maybe.mapOrElse (\_ -> "-sample") "") ++ "-sql-source"
    , details =
        [ ( "lines-count", parser.lines |> Maybe.mapOrElse List.length 0 |> String.fromInt )
        , ( "statements-count", parser.statements |> Maybe.mapOrElse Dict.size 0 |> String.fromInt )
        , ( "table-count", source.tables |> Dict.size |> String.fromInt )
        , ( "relation-count", source.relations |> List.length |> String.fromInt )
        , ( "parsing-errors", parser.commands |> Maybe.mapOrElse (Dict.count (\_ ( _, r ) -> r |> Result.isErr)) 0 |> String.fromInt )
        , ( "schema-errors", parser.schema |> Maybe.mapOrElse .errors [] |> List.length |> String.fromInt )
        ]
    , enabled = True
    }


projectEvent : String -> ProjectInfo -> TrackEvent
projectEvent eventName project =
    { name = eventName ++ Bool.cond (ProjectId.isSample project.id) "-sample" "" ++ "-project"
    , details =
        [ ( "table-count", project.tables |> String.fromInt )
        , ( "relation-count", project.relations |> String.fromInt )
        , ( "layout-count", project.layouts |> String.fromInt )
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
        , ( "ignored-columns", String.fromInt (result.settings.ignoredColumns |> String.split "," |> List.length) )
        , ( "ignored-tables", String.fromInt (result.settings.ignoredTables |> String.split "," |> List.length) )
        , ( "max-path-length", String.fromInt result.settings.maxPathLength )
        ]
    , enabled = True
    }
