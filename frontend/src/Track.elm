module Track exposing (SQLParsing, addSource, createLayout, createProject, deleteLayout, deleteProject, externalLink, findPathResult, initProject, loadLayout, loadProject, openEditNotes, openFindPath, openHelp, openIncomingRelationsDropdown, openSaveLayout, openSchemaAnalysis, openSettings, openSharing, openTableDropdown, openUpdateSchema, parsedDatabaseSource, parsedJsonSource, parsedSqlSource, proPlanLimit, refreshSource, showTableWithForeignKey, showTableWithIncomingRelationsDropdown, updateProject)

import DataSources.Helpers exposing (SourceLine)
import DataSources.SqlMiner.SqlAdapter exposing (SqlSchema)
import DataSources.SqlMiner.SqlParser exposing (Command)
import DataSources.SqlMiner.Utils.Types exposing (ParseError, SqlStatement)
import Dict exposing (Dict)
import Json.Encode as Encode
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Result as Result
import Models.OrganizationId exposing (OrganizationId)
import Models.Project exposing (Project)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.Source exposing (Source)
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.TrackEvent exposing (TrackClick, TrackEvent)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.FindPathResult exposing (FindPathResult)



-- all tracking events should be declared here to have a good overview of them


openSharing : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> TrackEvent
openSharing erd =
    -- TODO: onboarding goal
    createEvent "open-sharing" [] (erd |> Maybe.map .project)


openSettings : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> TrackEvent
openSettings erd =
    -- TODO: onboarding goal
    createEvent "open-settings" [] (erd |> Maybe.map .project)


openHelp : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> TrackEvent
openHelp erd =
    -- TODO: add source: top_navbar
    createEvent "editor_open_help" [] (erd |> Maybe.map .project)


openTableDropdown : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> TrackClick
openTableDropdown project =
    -- TODO: onboarding goal
    createClick "open-table-dropdown" [] (Just project)


showTableWithForeignKey : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> TrackClick
showTableWithForeignKey project =
    -- TODO: onboarding goal
    createClick "show-table-with-foreign-key" [] (Just project)


showTableWithIncomingRelationsDropdown : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> TrackClick
showTableWithIncomingRelationsDropdown project =
    -- TODO: onboarding goal
    createClick "show-table-with-incoming-relations-dropdown" [] (Just project)


openIncomingRelationsDropdown : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> TrackClick
openIncomingRelationsDropdown project =
    -- TODO: onboarding goal
    createClick "open-incoming-relations-dropdown" [] (Just project)


openSaveLayout : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> TrackEvent
openSaveLayout erd =
    createEvent "open-save-layout" [] (erd |> Maybe.map .project)


openEditNotes : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> TrackEvent
openEditNotes erd =
    createEvent "open-edit-notes" [] (erd |> Maybe.map .project)


openUpdateSchema : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> TrackEvent
openUpdateSchema erd =
    -- TODO add source
    createEvent "open-update-schema" [] (erd |> Maybe.map .project)


parsedDatabaseSource : Result String Source -> TrackEvent
parsedDatabaseSource =
    -- TODO: one event for all sources with a kind (sql, json, database...) detail: "editor_parse_source"
    parseDatabaseEvent


parsedSqlSource : SQLParsing msg -> Source -> TrackEvent
parsedSqlSource =
    parseSqlEvent


parsedJsonSource : Result String Source -> TrackEvent
parsedJsonSource =
    parseJsonEvent


loadProject : ProjectInfo -> TrackClick
loadProject =
    -- FIXME: removed with legacy projects
    projectClick "load"


initProject : Project -> TrackEvent
initProject project =
    projectEvent "init" (ProjectInfo.fromProject project)


createProject : Project -> TrackEvent
createProject project =
    -- TODO: already in backend
    projectEvent "create" (ProjectInfo.fromProject project)


updateProject : Project -> TrackEvent
updateProject project =
    -- TODO: already in backend
    projectEvent "update" (ProjectInfo.fromProject project)


deleteProject : ProjectInfo -> TrackEvent
deleteProject =
    -- TODO: already in backend
    projectEvent "delete"



-- TODO: add event on "editor_source_add_modal_opened"


addSource : Source -> TrackEvent
addSource =
    -- TODO: "editor_source_added"
    sourceEvent "add"


refreshSource : Source -> TrackEvent
refreshSource =
    sourceEvent "refresh"


createLayout : { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> ErdLayout -> TrackEvent
createLayout =
    createLayoutEvent "create"


loadLayout : { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> ErdLayout -> TrackEvent
loadLayout =
    createLayoutEvent "load"


deleteLayout : { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> ErdLayout -> TrackEvent
deleteLayout =
    createLayoutEvent "delete"


externalLink : String -> TrackClick
externalLink url =
    { name = "external_link_clicked", details = [ ( "url", url ), ( "source", "editor" ) ], organization = Nothing, project = Nothing }


openFindPath : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> TrackEvent
openFindPath erd =
    createEvent "editor_find_path_opened" [] (erd |> Maybe.map .project)


findPathResult : FindPathResult -> TrackEvent
findPathResult =
    findPathResults


openSchemaAnalysis : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> TrackEvent
openSchemaAnalysis erd =
    createEvent "editor_schema_analysis_opened" [] (erd |> Maybe.map .project)


proPlanLimit : String -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> TrackEvent
proPlanLimit limit erd =
    createEvent "pro_plan_limit" [ ( "limit", limit |> Encode.string ) ] (erd |> Maybe.map .project)



-- TODO: add memos
-- TODO: add events on search clicked: editor_search_clicked
-- HELPERS


createEvent : String -> List ( String, Encode.Value ) -> Maybe { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> TrackEvent
createEvent name details project =
    { name = name, details = details, organization = project |> Maybe.andThen .organization |> Maybe.map .id, project = project |> Maybe.map .id }


createClick : String -> List ( String, String ) -> Maybe { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> TrackClick
createClick name details project =
    { name = name, details = details, organization = project |> Maybe.andThen .organization |> Maybe.map .id, project = project |> Maybe.map .id }


parseDatabaseEvent : Result String Source -> TrackEvent
parseDatabaseEvent source =
    { name = "parse" ++ (source |> Result.toMaybe |> Maybe.andThen .fromSample |> Maybe.mapOrElse (\_ -> "-sample") "") ++ "-database-source"
    , details =
        source
            |> Result.fold
                (\e -> [ ( "error", e |> Encode.string ) ])
                (\s ->
                    [ ( "nb-table", s.tables |> Dict.size |> Encode.int )
                    , ( "nb-relation", s.relations |> List.length |> Encode.int )
                    ]
                )
    , organization = Nothing
    , project = Nothing
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
        [ ( "nb-lines", parser.lines |> Maybe.mapOrElse List.length 0 |> Encode.int )
        , ( "nb-statements", parser.statements |> Maybe.mapOrElse Dict.size 0 |> Encode.int )
        , ( "nb-table", source.tables |> Dict.size |> Encode.int )
        , ( "nb-relation", source.relations |> List.length |> Encode.int )
        , ( "parsing-errors", parser.commands |> Maybe.mapOrElse (Dict.count (\_ ( _, r ) -> r |> Result.isErr)) 0 |> Encode.int )
        , ( "schema-errors", parser.schema |> Maybe.mapOrElse .errors [] |> List.length |> Encode.int )
        ]
    , organization = Nothing
    , project = Nothing
    }


parseJsonEvent : Result String Source -> TrackEvent
parseJsonEvent source =
    { name = "parse" ++ (source |> Result.toMaybe |> Maybe.andThen .fromSample |> Maybe.mapOrElse (\_ -> "-sample") "") ++ "-json-source"
    , details =
        source
            |> Result.fold
                (\e -> [ ( "error", e |> Encode.string ) ])
                (\s ->
                    [ ( "nb-table", s.tables |> Dict.size |> Encode.int )
                    , ( "nb-relation", s.relations |> List.length |> Encode.int )
                    ]
                )
    , organization = Nothing
    , project = Nothing
    }


projectEvent : String -> ProjectInfo -> TrackEvent
projectEvent eventName project =
    { name = eventName ++ Bool.cond (ProjectId.isSample project.id) "-sample" "" ++ "-project"
    , details = projectStats project |> List.map (\( k, v ) -> ( k, v |> Encode.int ))
    , organization = project.organization |> Maybe.map .id
    , project = Just project.id
    }


projectClick : String -> ProjectInfo -> TrackClick
projectClick eventName project =
    { name = eventName ++ Bool.cond (ProjectId.isSample project.id) "-sample" "" ++ "-project"
    , details = projectStats project |> List.map (\( k, v ) -> ( k, v |> String.fromInt ))
    , organization = project.organization |> Maybe.map .id
    , project = Just project.id
    }


projectStats : ProjectInfo -> List ( String, Int )
projectStats project =
    [ ( "nb-source", project.nbSources )
    , ( "nb-table", project.nbTables )
    , ( "nb-column", project.nbColumns )
    , ( "nb-relation", project.nbRelations )
    , ( "nb-type", project.nbTypes )
    , ( "nb-comment", project.nbComments )
    , ( "nb-layout", project.nbLayouts )
    , ( "nb-note", project.nbNotes )
    , ( "nb-memos", project.nbMemos )
    ]


sourceEvent : String -> Source -> TrackEvent
sourceEvent eventName source =
    { name = eventName ++ "-source"
    , details =
        [ ( "nb-table", source.tables |> Dict.size |> Encode.int )
        , ( "nb-relation", source.relations |> List.length |> Encode.int )
        ]
    , organization = Nothing
    , project = Nothing
    }


createLayoutEvent : String -> { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> ErdLayout -> TrackEvent
createLayoutEvent eventName erd layout =
    createEvent (eventName ++ "-layout")
        [ ( "nb-table", layout.tables |> List.length |> Encode.int )
        , ( "nb-memos", layout.memos |> List.length |> Encode.int )
        ]
        (Just erd.project)


findPathResults : FindPathResult -> TrackEvent
findPathResults result =
    -- TODO: nb results
    { name = "editor_find_path_searched"
    , details =
        [ ( "found-paths", result.paths |> List.length |> Encode.int )
        , ( "ignored-columns", result.settings.ignoredColumns |> String.split "," |> List.length |> Encode.int )
        , ( "ignored-tables", result.settings.ignoredTables |> String.split "," |> List.length |> Encode.int )
        , ( "max-path-length", result.settings.maxPathLength |> Encode.int )
        ]
    , organization = Nothing
    , project = Nothing
    }
