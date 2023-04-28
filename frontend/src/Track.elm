module Track exposing (SQLParsing, amlSourceCreated, dbAnalysisOpened, dbSourceCreated, docOpened, externalLink, findPathOpened, findPathResults, jsonError, jsonSourceCreated, layoutCreated, layoutDeleted, layoutLoaded, memoDeleted, memoSaved, notFound, notesCreated, notesDeleted, notesUpdated, planLimit, projectDraftCreated, searchClicked, sourceAdded, sourceDeleted, sourceRefreshed, sqlSourceCreated, tagsCreated, tagsDeleted, tagsUpdated)

import Conf exposing (Feature, Features)
import DataSources.Helpers exposing (SourceLine)
import DataSources.SqlMiner.SqlAdapter exposing (SqlSchema)
import DataSources.SqlMiner.SqlParser exposing (Command)
import DataSources.SqlMiner.Utils.Types exposing (ParseError, SqlStatement)
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Models.Notes exposing (Notes)
import Libs.Models.Tag exposing (Tag)
import Libs.Result as Result
import Models.OrganizationId exposing (OrganizationId)
import Models.Plan as Plan
import Models.Project exposing (Project)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.Source exposing (Source)
import Models.Project.SourceKind as SourceKind
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.TrackEvent exposing (TrackClick, TrackEvent)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.FindPathResult exposing (FindPathResult)
import Ports



-- all tracking events should be declared here to have a good overview of all of them


dbSourceCreated : Maybe ProjectInfo -> Result String Source -> Cmd msg
dbSourceCreated project source =
    sendEvent "editor_source_created" ([ ( "format", "database" |> Encode.string ) ] ++ dbSourceDetails source) project


sqlSourceCreated : Maybe ProjectInfo -> SQLParsing m -> Source -> Cmd msg
sqlSourceCreated project parser source =
    sendEvent "editor_source_created" ([ ( "format", "sql" |> Encode.string ) ] ++ sqlSourceDetails parser source) project


jsonSourceCreated : Maybe ProjectInfo -> Result String Source -> Cmd msg
jsonSourceCreated project source =
    sendEvent "editor_source_created" ([ ( "format", "json" |> Encode.string ) ] ++ jsonSourceDetails source) project


amlSourceCreated : Maybe ProjectInfo -> Source -> Cmd msg
amlSourceCreated project source =
    sendEvent "editor_source_created" ([ ( "format", "aml" |> Encode.string ) ] ++ sourceDetails source) project


projectDraftCreated : Project -> Cmd msg
projectDraftCreated project =
    sendEvent "editor_project_draft_created" (project |> ProjectInfo.fromProject |> projectDetails) (Just project)


sourceAdded : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Source -> Cmd msg
sourceAdded erd source =
    sendEvent "editor_source_added" (sourceDetails source) (erd |> Maybe.map .project)


sourceRefreshed : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Source -> Cmd msg
sourceRefreshed erd source =
    sendEvent "editor_source_refreshed" (sourceDetails source) (erd |> Maybe.map .project)


sourceDeleted : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Source -> Cmd msg
sourceDeleted erd source =
    sendEvent "editor_source_deleted" (sourceDetails source) (erd |> Maybe.map .project)


layoutCreated : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> ErdLayout -> Cmd msg
layoutCreated project layout =
    sendEvent "editor_layout_created" (layoutDetails layout) (Just project)


layoutLoaded : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> ErdLayout -> Cmd msg
layoutLoaded project layout =
    sendEvent "editor_layout_loaded" (layoutDetails layout) (Just project)


layoutDeleted : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> ErdLayout -> Cmd msg
layoutDeleted project layout =
    sendEvent "editor_layout_deleted" (layoutDetails layout) (Just project)


searchClicked : String -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
searchClicked kind erd =
    sendEvent "editor_search_clicked" [ ( "kind", kind |> Encode.string ) ] (erd |> Maybe.map .project)


notesCreated : Notes -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
notesCreated content erd =
    sendEvent "editor_notes_created" [ ( "length", content |> String.length |> Encode.int ) ] (erd |> Maybe.map .project)


notesUpdated : Notes -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
notesUpdated content erd =
    sendEvent "editor_notes_updated" [ ( "length", content |> String.length |> Encode.int ) ] (erd |> Maybe.map .project)


notesDeleted : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
notesDeleted erd =
    sendEvent "editor_notes_deleted" [] (erd |> Maybe.map .project)


tagsCreated : List Tag -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
tagsCreated content erd =
    sendEvent "editor_tags_created" [ ( "length", content |> List.length |> Encode.int ) ] (erd |> Maybe.map .project)


tagsUpdated : List Tag -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
tagsUpdated content erd =
    sendEvent "editor_tags_updated" [ ( "length", content |> List.length |> Encode.int ) ] (erd |> Maybe.map .project)


tagsDeleted : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
tagsDeleted erd =
    sendEvent "editor_tags_deleted" [] (erd |> Maybe.map .project)


memoSaved : Bool -> String -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
memoSaved createMode content erd =
    sendEvent (Bool.cond createMode "editor_memo_created" "editor_memo_updated") [ ( "length", content |> String.length |> Encode.int ) ] (erd |> Maybe.map .project)


memoDeleted : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
memoDeleted erd =
    sendEvent "editor_memo_deleted" [] (erd |> Maybe.map .project)


findPathOpened : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
findPathOpened erd =
    sendEvent "editor_find_path_opened" [] (erd |> Maybe.map .project)


findPathResults : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> FindPathResult -> Cmd msg
findPathResults erd result =
    sendEvent "editor_find_path_searched" (findPathDetails result) (erd |> Maybe.map .project)


dbAnalysisOpened : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
dbAnalysisOpened erd =
    sendEvent "editor_db_analysis_opened" [] (erd |> Maybe.map .project)


docOpened : String -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
docOpened source erd =
    sendEvent "editor_doc_opened" [ ( "source", source |> Encode.string ) ] (erd |> Maybe.map .project)


planLimit : (Features -> Feature a) -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId, plan : { pl | id : String } }, id : ProjectId } } -> Cmd msg
planLimit getFeature erd =
    sendEvent "plan_limit"
        [ ( "plan", erd |> Maybe.andThen (.project >> .organization) |> Maybe.mapOrElse (.plan >> .id) Plan.free.id |> Encode.string )
        , ( "feature", Conf.features |> getFeature |> .name |> Encode.string )
        ]
        (erd |> Maybe.map .project)


externalLink : String -> TrackClick
externalLink url =
    { name = "external_link_clicked", details = [ ( "source", "editor" ), ( "url", url ) ], organization = Nothing, project = Nothing }


jsonError : String -> Decode.Error -> Cmd msg
jsonError kind error =
    sendEvent "editor_json_error" [ ( "kind", kind |> Encode.string ), ( "message", Decode.errorToString error |> Encode.string ) ] Nothing


notFound : String -> Cmd msg
notFound url =
    sendEvent "not_found" [ ( "url", url |> Encode.string ) ] Nothing



-- HELPERS


sendEvent : String -> List ( String, Encode.Value ) -> Maybe { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> Cmd msg
sendEvent name details project =
    { name = name
    , details = details
    , organization = project |> Maybe.andThen .organization |> Maybe.map .id
    , project = project |> Maybe.map .id |> Maybe.filter (\id -> id /= ProjectId.zero)
    }
        |> Ports.track



--createClick : String -> List ( String, String ) -> Maybe { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> TrackClick
--createClick name details project =
--    { name = name, details = details, organization = project |> Maybe.andThen .organization |> Maybe.map .id, project = project |> Maybe.map .id }


dbSourceDetails : Result String Source -> List ( String, Encode.Value )
dbSourceDetails source =
    source |> Result.fold (\e -> [ ( "error", e |> Encode.string ) ]) sourceDetails


type alias SQLParsing x =
    { x
        | lines : Maybe (List SourceLine)
        , statements : Maybe (Dict Int SqlStatement)
        , commands : Maybe (Dict Int ( SqlStatement, Result (List ParseError) Command ))
        , schema : Maybe SqlSchema
    }


sqlSourceDetails : SQLParsing msg -> Source -> List ( String, Encode.Value )
sqlSourceDetails parser source =
    [ ( "nb_lines", parser.lines |> Maybe.mapOrElse List.length 0 |> Encode.int )
    , ( "nb_statements", parser.statements |> Maybe.mapOrElse Dict.size 0 |> Encode.int )
    , ( "nb_parsing_errors", parser.commands |> Maybe.mapOrElse (Dict.count (\_ ( _, r ) -> r |> Result.isErr)) 0 |> Encode.int )
    , ( "nb_schema_errors", parser.schema |> Maybe.mapOrElse .errors [] |> List.length |> Encode.int )
    ]
        ++ sourceDetails source


jsonSourceDetails : Result String Source -> List ( String, Encode.Value )
jsonSourceDetails source =
    source |> Result.fold (\e -> [ ( "error", e |> Encode.string ) ]) sourceDetails


projectDetails : ProjectInfo -> List ( String, Encode.Value )
projectDetails project =
    [ ( "nb_sources", project.nbSources |> Encode.int )
    , ( "nb_tables", project.nbTables |> Encode.int )
    , ( "nb_columns", project.nbColumns |> Encode.int )
    , ( "nb_relations", project.nbRelations |> Encode.int )
    , ( "nb_types", project.nbTypes |> Encode.int )
    , ( "nb_comments", project.nbComments |> Encode.int )
    , ( "nb_layouts", project.nbLayouts |> Encode.int )
    , ( "nb_notes", project.nbNotes |> Encode.int )
    , ( "nb_memos", project.nbMemos |> Encode.int )
    ]


sourceDetails : Source -> List ( String, Encode.Value )
sourceDetails source =
    [ ( "kind", source.kind |> SourceKind.toString |> Encode.string )
    , ( "nb_table", source.tables |> Dict.size |> Encode.int )
    , ( "nb_relation", source.relations |> List.length |> Encode.int )
    ]


layoutDetails : ErdLayout -> List ( String, Encode.Value )
layoutDetails layout =
    [ ( "nb_table", layout.tables |> List.length |> Encode.int )
    , ( "nb_memos", layout.memos |> List.length |> Encode.int )
    ]


findPathDetails : FindPathResult -> List ( String, Encode.Value )
findPathDetails result =
    [ ( "nb_results", result.paths |> List.length |> Encode.int )
    , ( "nb_ignored_columns", result.settings.ignoredColumns |> String.split "," |> List.length |> Encode.int )
    , ( "nb_ignored_tables", result.settings.ignoredTables |> String.split "," |> List.length |> Encode.int )
    , ( "path_max_length", result.settings.maxPathLength |> Encode.int )
    ]
