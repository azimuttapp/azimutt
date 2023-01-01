module Track exposing (SQLParsing, addSource, createLayout, createProject, deleteLayout, deleteProject, externalLink, findPathResult, initProject, loadLayout, loadProject, openEditNotes, openFindPath, openHelp, openIncomingRelationsDropdown, openSaveLayout, openSchemaAnalysis, openSettings, openSharing, openTableDropdown, openUpdateSchema, parsedDatabaseSource, parsedJsonSource, parsedSqlSource, proPlanLimit, refreshSource, showTableWithForeignKey, showTableWithIncomingRelationsDropdown, updateProject)

import DataSources.Helpers exposing (SourceLine)
import DataSources.SqlMiner.SqlAdapter exposing (SqlSchema)
import DataSources.SqlMiner.SqlParser exposing (Command)
import DataSources.SqlMiner.Utils.Types exposing (ParseError, SqlStatement)
import Dict exposing (Dict)
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Models exposing (TrackEvent)
import Libs.Result as Result
import Models.Project exposing (Project)
import Models.Project.ProjectId as ProjectId
import Models.Project.Source exposing (Source)
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.FindPathResult exposing (FindPathResult)



-- all tracking events should be declared here to have a good overview of them


openSharing : TrackEvent
openSharing =
    { name = "open-sharing", details = [], enabled = True }


openSettings : TrackEvent
openSettings =
    { name = "open-settings", details = [], enabled = True }


openHelp : TrackEvent
openHelp =
    { name = "open-help", details = [], enabled = True }


openTableDropdown : TrackEvent
openTableDropdown =
    { name = "open-table-dropdown", details = [], enabled = True }


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


openUpdateSchema : TrackEvent
openUpdateSchema =
    { name = "open-update-schema", details = [], enabled = True }


parsedDatabaseSource : Result String Source -> TrackEvent
parsedDatabaseSource =
    parseDatabaseEvent


parsedSqlSource : SQLParsing msg -> Source -> TrackEvent
parsedSqlSource =
    parseSqlEvent


parsedJsonSource : Result String Source -> TrackEvent
parsedJsonSource =
    parseJsonEvent


loadProject : ProjectInfo -> TrackEvent
loadProject =
    projectEvent "load"


initProject : Project -> TrackEvent
initProject project =
    projectEvent "init" (ProjectInfo.fromProject project)


createProject : Project -> TrackEvent
createProject project =
    projectEvent "create" (ProjectInfo.fromProject project)


updateProject : Project -> TrackEvent
updateProject project =
    projectEvent "update" (ProjectInfo.fromProject project)


deleteProject : ProjectInfo -> TrackEvent
deleteProject =
    projectEvent "delete"


addSource : Source -> TrackEvent
addSource =
    sourceEvent "add"


refreshSource : Source -> TrackEvent
refreshSource =
    sourceEvent "refresh"


createLayout : ErdLayout -> TrackEvent
createLayout =
    layoutEvent "create"


loadLayout : ErdLayout -> TrackEvent
loadLayout =
    layoutEvent "load"


deleteLayout : ErdLayout -> TrackEvent
deleteLayout =
    layoutEvent "delete"


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


proPlanLimit : String -> Erd -> TrackEvent
proPlanLimit limit erd =
    { name = "pro_plan_limit", details = [ ( "limit", limit ) ] ++ projectRefs erd, enabled = True }


projectRefs : Erd -> List ( String, String )
projectRefs erd =
    [ erd.project.organization |> Maybe.map (\o -> ( "organization_id", o.id ))
    , Just erd.project.id |> Maybe.filter (\id -> id /= ProjectId.zero) |> Maybe.map (\id -> ( "project_id", id ))
    ]
        |> List.filterMap identity



-- HELPERS


parseDatabaseEvent : Result String Source -> TrackEvent
parseDatabaseEvent source =
    { name = "parse" ++ (source |> Result.toMaybe |> Maybe.andThen .fromSample |> Maybe.mapOrElse (\_ -> "-sample") "") ++ "-database-source"
    , details =
        source
            |> Result.fold (\e -> [ ( "error", e ) ])
                (\s ->
                    [ ( "table-count", s.tables |> Dict.size |> String.fromInt )
                    , ( "relation-count", s.relations |> List.length |> String.fromInt )
                    ]
                )
    , enabled = True
    }


type alias SQLParsing x =
    { x
        | lines : Maybe (List SourceLine)
        , statements : Maybe (Dict Int SqlStatement)
        , commands : Maybe (Dict Int ( SqlStatement, Result (List ParseError) Command ))
        , schema : Maybe SqlSchema
    }


parseSqlEvent : SQLParsing msg -> Source -> TrackEvent
parseSqlEvent parser source =
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


parseJsonEvent : Result String Source -> TrackEvent
parseJsonEvent source =
    { name = "parse" ++ (source |> Result.toMaybe |> Maybe.andThen .fromSample |> Maybe.mapOrElse (\_ -> "-sample") "") ++ "-json-source"
    , details =
        source
            |> Result.fold (\e -> [ ( "error", e ) ])
                (\s ->
                    [ ( "table-count", s.tables |> Dict.size |> String.fromInt )
                    , ( "relation-count", s.relations |> List.length |> String.fromInt )
                    ]
                )
    , enabled = True
    }


projectEvent : String -> ProjectInfo -> TrackEvent
projectEvent eventName project =
    { name = eventName ++ Bool.cond (ProjectId.isSample project.id) "-sample" "" ++ "-project"
    , details =
        [ ( "source-count", project.nbSources |> String.fromInt )
        , ( "table-count", project.nbTables |> String.fromInt )
        , ( "column-count", project.nbColumns |> String.fromInt )
        , ( "relation-count", project.nbRelations |> String.fromInt )
        , ( "type-count", project.nbTypes |> String.fromInt )
        , ( "comment-count", project.nbComments |> String.fromInt )
        , ( "note-count", project.nbNotes |> String.fromInt )
        , ( "layout-count", project.nbLayouts |> String.fromInt )
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


layoutEvent : String -> ErdLayout -> TrackEvent
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
