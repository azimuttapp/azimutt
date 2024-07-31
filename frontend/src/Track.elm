module Track exposing (SQLParsing, amlSourceCreated, dataExplorerDetailsOpened, dataExplorerDetailsResult, dataExplorerOpened, dataExplorerQueryOpened, dataExplorerQueryResult, dbAnalysisOpened, detailSidebarClosed, detailSidebarOpened, docOpened, externalLink, findPathOpened, findPathResults, generateSqlFailed, generateSqlOpened, generateSqlQueried, generateSqlReplied, generateSqlSucceeded, groupCreated, groupDeleted, groupRenamed, jsonError, layoutCreated, layoutDeleted, layoutLoaded, layoutRenamed, memoDeleted, memoSaved, notFound, notesCreated, notesDeleted, notesUpdated, planLimit, projectDraftCreated, projectLoaded, searchClicked, sourceAdded, sourceCreated, sourceDeleted, sourceEditorClosed, sourceEditorOpened, sourceRefreshed, sqlSourceCreated, tableRowOpened, tableRowResult, tableRowShown, tableShown, tagsCreated, tagsDeleted, tagsUpdated)

import DataSources.Helpers exposing (SourceLine)
import DataSources.SqlMiner.SqlAdapter exposing (SqlSchema)
import DataSources.SqlMiner.SqlParser exposing (Command)
import DataSources.SqlMiner.Utils.Types exposing (ParseError, SqlStatement)
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.Json.Encode as Encode
import Libs.Maybe as Maybe
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.Models.Notes exposing (Notes)
import Libs.Models.Tag exposing (Tag)
import Libs.Result as Result
import Models.OpenAIModel as OpenAIModel exposing (OpenAIModel)
import Models.OrganizationId exposing (OrganizationId)
import Models.Project exposing (Project)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind as SourceKind
import Models.Project.TableRow as TableRow
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.QueryResult exposing (QueryResult)
import Models.SqlQuery exposing (SqlQuery, SqlQueryOrigin)
import Models.TrackEvent exposing (TrackClick, TrackEvent)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.FindPathResult exposing (FindPathResult)
import Ports
import Time



-- all tracking events should be declared here to have a good overview of all of them


sourceCreated : Maybe ProjectInfo -> String -> Result String Source -> Cmd msg
sourceCreated project format sourceRes =
    case sourceRes of
        Ok source ->
            sendEvent "editor_source_created" ([ ( "format", format |> Encode.string ) ] ++ sourceDetails source) project

        Err err ->
            sendEvent "editor_source_creation_error" [ ( "format", format |> Encode.string ), ( "error", err |> Encode.string ) ] project


sqlSourceCreated : Maybe ProjectInfo -> SQLParsing m -> Source -> Cmd msg
sqlSourceCreated project parser source =
    sendEvent "editor_source_created" ([ ( "format", "sql" |> Encode.string ) ] ++ sqlSourceDetails parser source) project


amlSourceCreated : Maybe ProjectInfo -> Source -> Cmd msg
amlSourceCreated project source =
    -- when a source is created, may be added to a project or not
    sendEvent "editor_source_created" ([ ( "format", "aml" |> Encode.string ) ] ++ sourceDetails source) project


projectDraftCreated : Project -> Cmd msg
projectDraftCreated project =
    sendEvent "editor_project_draft_created" (project |> ProjectInfo.fromProject |> projectDetails) (Just project)


projectLoaded : Project -> Cmd msg
projectLoaded project =
    sendEvent "project_loaded" (project |> ProjectInfo.fromProject |> projectDetails) (Just project)


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


layoutRenamed : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> ErdLayout -> Cmd msg
layoutRenamed project layout =
    sendEvent "editor_layout_renamed" (layoutDetails layout) (Just project)


layoutLoaded : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> ErdLayout -> Cmd msg
layoutLoaded project layout =
    sendEvent "editor_layout_loaded" (layoutDetails layout) (Just project)


layoutDeleted : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> ErdLayout -> Cmd msg
layoutDeleted project layout =
    sendEvent "editor_layout_deleted" (layoutDetails layout) (Just project)


searchClicked : String -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
searchClicked kind erd =
    sendEvent "editor_search_clicked" [ ( "kind", kind |> Encode.string ) ] (erd |> Maybe.map .project)


tableShown : Int -> String -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
tableShown tables from erd =
    sendEvent "editor__table__shown" [ ( "nb_tables", tables |> Encode.int ), ( "from", from |> Encode.string ) ] (erd |> Maybe.map .project)


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


groupCreated : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
groupCreated erd =
    sendEvent "editor_group_created" [] (erd |> Maybe.map .project)


groupRenamed : String -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
groupRenamed name erd =
    sendEvent "editor_group_renamed" [ ( "length", name |> String.length |> Encode.int ) ] (erd |> Maybe.map .project)


groupDeleted : String -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
groupDeleted name erd =
    sendEvent "editor_group_deleted" [ ( "length", name |> String.length |> Encode.int ) ] (erd |> Maybe.map .project)


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


detailSidebarOpened : String -> { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
detailSidebarOpened level erd =
    sendEvent "editor__detail_sidebar__opened" [ ( "level", level |> Encode.string ) ] (Just erd.project)


detailSidebarClosed : { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
detailSidebarClosed erd =
    sendEvent "editor__detail_sidebar__closed" [] (Just erd.project)


sourceEditorOpened : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
sourceEditorOpened erd =
    sendEvent "editor__source_editor__opened" [] (erd |> Maybe.map .project)


sourceEditorClosed : Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } } -> Cmd msg
sourceEditorClosed erd =
    sendEvent "editor__source_editor__closed" [] (erd |> Maybe.map .project)


dataExplorerOpened : List Source -> Maybe { s | db : { d | kind : DatabaseKind } } -> Maybe SqlQueryOrigin -> { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> Cmd msg
dataExplorerOpened sources source query project =
    sendEvent "editor__data_explorer__opened"
        [ ( "nb_sources", sources |> List.length |> Encode.int )
        , ( "nb_db_sources", sources |> List.filter (.kind >> SourceKind.isDatabase) |> List.length |> Encode.int )
        , ( "db", source |> Maybe.map (.db >> .kind) |> Encode.maybe DatabaseKind.encode )
        , ( "query", query |> Maybe.map .origin |> Encode.maybe Encode.string )
        ]
        (Just project)


dataExplorerQueryOpened : { s | db : { d | kind : DatabaseKind } } -> SqlQueryOrigin -> { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> Cmd msg
dataExplorerQueryOpened source query project =
    sendEvent "data_explorer__query__opened" [ ( "db", source.db.kind |> DatabaseKind.encode ), ( "query", query.origin |> Encode.string ) ] (Just project)


dataExplorerQueryResult : QueryResult -> { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> Cmd msg
dataExplorerQueryResult res project =
    sendEvent "data_explorer__query__result" (queryResultDetails res) (Just project)


dataExplorerDetailsOpened : { s | db : { d | kind : DatabaseKind } } -> SqlQueryOrigin -> { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> Cmd msg
dataExplorerDetailsOpened source query project =
    sendEvent "data_explorer__details__opened" [ ( "db", source.db.kind |> DatabaseKind.encode ), ( "query", query.origin |> Encode.string ) ] (Just project)


dataExplorerDetailsResult : QueryResult -> { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> Cmd msg
dataExplorerDetailsResult res project =
    sendEvent "data_explorer__details__result" (queryResultDetails res) (Just project)


tableRowShown : { s | db : { d | kind : DatabaseKind } } -> String -> { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> Cmd msg
tableRowShown source from project =
    sendEvent "data_explorer__table_row__shown" [ ( "db", source.db.kind |> DatabaseKind.encode ), ( "from", from |> Encode.string ) ] (Just project)


tableRowOpened : Maybe TableRow.SuccessState -> { s | db : { d | kind : DatabaseKind } } -> SqlQueryOrigin -> { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> Cmd msg
tableRowOpened previous source query project =
    sendEvent "data_explorer__table_row__opened" [ ( "db", source.db.kind |> DatabaseKind.encode ), ( "query", query.origin |> Encode.string ), ( "previous", previous /= Nothing |> Encode.bool ) ] (Just project)


tableRowResult : QueryResult -> { p | organization : Maybe { o | id : OrganizationId }, id : ProjectId } -> Cmd msg
tableRowResult res project =
    sendEvent "data_explorer__table_row__result" (queryResultDetails res) (Just project)


generateSqlOpened : ProjectInfo -> Maybe Source -> Cmd msg
generateSqlOpened project source =
    sendEvent "editor__generate_sql__opened" (source |> Maybe.mapOrElse sourceDetails []) (Just project)


generateSqlQueried : ProjectInfo -> Source -> OpenAIModel -> String -> Cmd msg
generateSqlQueried project source llm prompt =
    sendEvent "editor__generate_sql__queried" ([ ( "llm", llm |> OpenAIModel.encode ), ( "prompt_length", prompt |> String.length |> Encode.int ) ] ++ sourceDetails source) (Just project)


generateSqlReplied : ProjectInfo -> Maybe Source -> OpenAIModel -> String -> Result String SqlQuery -> Cmd msg
generateSqlReplied project source llm prompt reply =
    sendEvent "editor__generate_sql__replied" ([ ( "llm", llm |> OpenAIModel.encode ), ( "prompt_length", prompt |> String.length |> Encode.int ), reply |> Result.fold (\err -> ( "error_length", err |> String.length |> Encode.int )) (\q -> ( "query_length", q |> String.length |> Encode.int )) ] ++ (source |> Maybe.mapOrElse sourceDetails [])) (Just project)


generateSqlSucceeded : ProjectInfo -> Maybe Source -> OpenAIModel -> String -> SqlQuery -> Cmd msg
generateSqlSucceeded project source llm prompt query =
    sendEvent "editor__generate_sql__succeeded" ([ ( "llm", llm |> OpenAIModel.encode ), ( "prompt_length", prompt |> String.length |> Encode.int ), ( "query_length", query |> String.length |> Encode.int ) ] ++ (source |> Maybe.mapOrElse sourceDetails [])) (Just project)


generateSqlFailed : ProjectInfo -> Maybe Source -> OpenAIModel -> String -> SqlQuery -> Cmd msg
generateSqlFailed project source llm prompt query =
    sendEvent "editor__generate_sql__failed" ([ ( "llm", llm |> OpenAIModel.encode ), ( "prompt", prompt |> Encode.string ), ( "query", query |> Encode.string ) ] ++ (source |> Maybe.mapOrElse sourceDetails [])) (Just project)


planLimit : { x | name : String } -> Maybe { e | project : { p | organization : Maybe { o | id : OrganizationId, plan : { pl | id : String } }, id : ProjectId } } -> Cmd msg
planLimit feature erd =
    sendEvent "plan_limit"
        [ ( "plan", erd |> Maybe.andThen (.project >> .organization) |> Maybe.mapOrElse (.plan >> .id) "unknown" |> Encode.string )
        , ( "feature", feature.name |> Encode.string )
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
    [ ( "source_id", source.id |> SourceId.encode )
    , ( "source_kind", source.kind |> SourceKind.toString |> Encode.string )
    , ( "source_dialect", source |> Source.databaseKind |> Maybe.mapOrElse DatabaseKind.toString "" |> Encode.string )
    , ( "nb_table", source.tables |> Dict.size |> Encode.int )
    , ( "nb_columns", source.tables |> Dict.foldl (\_ t c -> c + Dict.size t.columns) 0 |> Encode.int )
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


queryResultDetails : QueryResult -> List ( String, Encode.Value )
queryResultDetails res =
    (res.result
        |> Result.fold (\err -> [ ( "error", err |> Encode.string ) ])
            (\r ->
                [ ( "rows", r.rows |> List.length |> Encode.int )
                , ( "columns", r.columns |> List.length |> Encode.int )
                , ( "column_refs", r.columns |> List.filter (\c -> c.ref /= Nothing) |> List.length |> Encode.int )
                ]
            )
    )
        ++ [ ( "db", res.query.db |> DatabaseKind.encode ), ( "query", res.query.origin |> Encode.string ), ( "duration", Time.posixToMillis res.finished - Time.posixToMillis res.started |> Encode.int ) ]
