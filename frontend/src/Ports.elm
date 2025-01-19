port module Ports exposing (JsMsg(..), MetaInfos, autofocusWithin, blur, click, confetti, confettiPride, copyToClipboard, createProject, createProjectTmp, deleteProject, deleteSource, downloadFile, fireworks, focus, fullscreen, getAmlSchema, getAutoLayout, getCode, getColumnStats, getDatabaseSchema, getPrismaSchema, getProject, getTableStats, listenHotkeys, llmGenerateSql, llmLayoutFromSql, llmLayoutPrompt, mouseDown, moveProjectTo, observeLayout, observeLinkSize, observeMemoSize, observeSize, observeTableRowSize, observeTableSize, observeTablesSize, onJsMessage, projectDirty, readLocalFile, runDatabaseQuery, scrollTo, setMeta, toast, track, unhandledJsMsgError, updateProject, updateProjectTmp)

import DataSources.JsonMiner.JsonSchema as JsonSchema exposing (JsonSchema)
import Dict exposing (Dict)
import FileValue exposing (File)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Models exposing (FileContent, SizeChange)
import Libs.Models.Area as Area exposing (Area)
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.Models.DatabaseUrl as DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.Delta as Delta exposing (Delta)
import Libs.Models.FileName exposing (FileName)
import Libs.Models.Hotkey as Hotkey exposing (Hotkey)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Color exposing (Color)
import Models.AutoLayout exposing (AutoLayoutMethod, DiagramEdge, DiagramNode, decodeDiagramNode, encodeAutoLayoutMethod, encodeDiagramEdge, encodeDiagramNode)
import Models.Dialect as Dialect exposing (Dialect)
import Models.OpenAIKey as OpenAIKey exposing (OpenAIKey)
import Models.OpenAIModel as OpenAIModel exposing (OpenAIModel)
import Models.OrganizationId as OrganizationId exposing (OrganizationId)
import Models.ParserError as ParserError exposing (ParserError)
import Models.Position as Position
import Models.Project as Project exposing (Project)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.ColumnStats as ColumnStats exposing (ColumnStats)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableRow as TableRow exposing (TableRow)
import Models.Project.TableStats as TableStats exposing (TableStats)
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.ProjectTokenId as ProjectTokenId exposing (ProjectTokenId)
import Models.QueryResult as QueryResult exposing (QueryResult)
import Models.Route as Route exposing (Route)
import Models.Size as Size
import Models.SqlQuery as SqlQuery exposing (SqlQuery, SqlQueryOrigin)
import Models.TrackEvent as TrackEvent exposing (TrackEvent)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.LinkLayoutId as LinkLayoutId exposing (LinkLayoutId)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId exposing (MemoId)
import Storage.ProjectV2 exposing (decodeProject)


click : HtmlId -> Cmd msg
click id =
    messageToJs (Click id)


mouseDown : HtmlId -> Cmd msg
mouseDown id =
    messageToJs (MouseDown id)


focus : HtmlId -> Cmd msg
focus id =
    messageToJs (Focus id)


blur : HtmlId -> Cmd msg
blur id =
    messageToJs (Blur id)


scrollTo : HtmlId -> String -> Cmd msg
scrollTo id position =
    messageToJs (ScrollTo id position)


fullscreen : Maybe HtmlId -> Cmd msg
fullscreen id =
    messageToJs (Fullscreen id)


setMeta : MetaInfos -> Cmd msg
setMeta payload =
    messageToJs (SetMeta payload)


autofocusWithin : HtmlId -> Cmd msg
autofocusWithin id =
    messageToJs (AutofocusWithin id)


toast : String -> String -> Cmd msg
toast level message =
    messageToJs (Toast level message)


getProject : OrganizationId -> ProjectId -> Maybe ProjectTokenId -> Cmd msg
getProject organization project token =
    messageToJs (GetProject organization project token)


createProjectTmp : Project -> Cmd msg
createProjectTmp project =
    messageToJs (CreateProjectTmp project)


updateProjectTmp : Project -> Cmd msg
updateProjectTmp project =
    messageToJs (UpdateProjectTmp project)


createProject : OrganizationId -> ProjectStorage -> Project -> Cmd msg
createProject organization storage project =
    messageToJs (CreateProject organization storage project)


updateProject : Project -> Cmd msg
updateProject project =
    messageToJs (UpdateProject project)


moveProjectTo : Project -> ProjectStorage -> Cmd msg
moveProjectTo project storage =
    messageToJs (MoveProjectTo project storage)


downloadFile : FileName -> FileContent -> Cmd msg
downloadFile filename content =
    messageToJs (DownloadFile filename content)


copyToClipboard : String -> Cmd msg
copyToClipboard content =
    messageToJs (CopyToClipboard content)


deleteProject : ProjectInfo -> Maybe String -> Cmd msg
deleteProject project redirect =
    messageToJs (DeleteProject project redirect)


deleteSource : SourceId -> Cmd msg
deleteSource source =
    messageToJs (DeleteSource source)


projectDirty : Bool -> Cmd msg
projectDirty dirty =
    messageToJs (ProjectDirty dirty)


readLocalFile : String -> File -> Cmd msg
readLocalFile sourceKind file =
    messageToJs (GetLocalFile sourceKind file)


getDatabaseSchema : DatabaseUrl -> Cmd msg
getDatabaseSchema database =
    messageToJs (GetDatabaseSchema database)


getTableStats : TableId -> ( SourceId, DatabaseUrl ) -> Cmd msg
getTableStats table ( source, database ) =
    messageToJs (GetTableStats source database table)


getColumnStats : ColumnRef -> ( SourceId, DatabaseUrl ) -> Cmd msg
getColumnStats column ( source, database ) =
    messageToJs (GetColumnStats source database column)


runDatabaseQuery : String -> SourceId -> DatabaseUrl -> SqlQueryOrigin -> Cmd msg
runDatabaseQuery context source database query =
    messageToJs (RunDatabaseQuery context source database query)


getAmlSchema : SourceId -> String -> Cmd msg
getAmlSchema source content =
    messageToJs (GetAmlSchema source content)


getPrismaSchema : String -> Cmd msg
getPrismaSchema content =
    messageToJs (GetPrismaSchema content)


getCode : Dialect -> JsonSchema -> Cmd msg
getCode dialect schema =
    messageToJs (GetCode dialect schema)


getAutoLayout : AutoLayoutMethod -> Area -> List DiagramNode -> List DiagramEdge -> Cmd msg
getAutoLayout method viewport nodes edges =
    messageToJs (GetAutoLayout method viewport nodes edges)


observeSize : HtmlId -> Cmd msg
observeSize id =
    observeSizes [ id ]


observeTableSize : TableId -> Cmd msg
observeTableSize id =
    observeSizes [ TableId.toHtmlId id ]


observeTablesSize : List TableId -> Cmd msg
observeTablesSize ids =
    observeSizes (List.map TableId.toHtmlId ids)


observeMemoSize : MemoId -> Cmd msg
observeMemoSize id =
    observeSizes [ MemoId.toHtmlId id ]


observeLinkSize : LinkLayoutId -> Cmd msg
observeLinkSize id =
    observeSizes [ LinkLayoutId.toHtmlId id ]


observeTableRowSize : TableRow.Id -> Cmd msg
observeTableRowSize id =
    observeSizes [ TableRow.toHtmlId id ]


observeLayout : ErdLayout -> Cmd msg
observeLayout layout =
    observeSizes
        ((layout.tables |> List.map (.id >> TableId.toHtmlId))
            ++ (layout.tableRows |> List.map (.id >> TableRow.toHtmlId))
            ++ (layout.memos |> List.map (.id >> MemoId.toHtmlId))
            ++ (layout.links |> List.map (.id >> LinkLayoutId.toHtmlId))
        )


observeSizes : List HtmlId -> Cmd msg
observeSizes ids =
    if ids |> List.isEmpty then
        Cmd.none

    else
        messageToJs (ObserveSizes ids)


llmGenerateSql : OpenAIKey -> OpenAIModel -> DatabaseKind -> Source -> String -> Cmd msg
llmGenerateSql apiKey model dialect source prompt =
    messageToJs (LlmGenerateSql apiKey model dialect source prompt)


llmLayoutPrompt : OpenAIKey -> OpenAIModel -> List Table -> String -> Cmd msg
llmLayoutPrompt apiKey model tables prompt =
    messageToJs (LlmLayoutPrompt apiKey model tables prompt)


llmLayoutFromSql : OpenAIKey -> OpenAIModel -> List Table -> String -> Cmd msg
llmLayoutFromSql apiKey model tables sql =
    messageToJs (LlmLayoutFromSql apiKey model tables sql)


listenHotkeys : Dict String (List Hotkey) -> Cmd msg
listenHotkeys keys =
    messageToJs (ListenKeys keys)


confetti : HtmlId -> Cmd msg
confetti id =
    messageToJs (Confetti id)


confettiPride : Cmd msg
confettiPride =
    messageToJs ConfettiPride


fireworks : Cmd msg
fireworks =
    messageToJs Fireworks


track : TrackEvent -> Cmd msg
track event =
    messageToJs (Track event)


type alias MetaInfos =
    { title : Maybe String
    , description : Maybe String
    , canonical : Maybe Route
    , html : Maybe String
    , body : Maybe String
    }


type ElmMsg
    = Click HtmlId
    | MouseDown HtmlId
    | Focus HtmlId
    | Blur HtmlId
    | ScrollTo HtmlId String
    | Fullscreen (Maybe HtmlId)
    | SetMeta MetaInfos
    | AutofocusWithin HtmlId
    | Toast String String
    | GetProject OrganizationId ProjectId (Maybe ProjectTokenId)
    | CreateProjectTmp Project
    | UpdateProjectTmp Project
    | CreateProject OrganizationId ProjectStorage Project
    | UpdateProject Project
    | MoveProjectTo Project ProjectStorage
    | DeleteProject ProjectInfo (Maybe String)
    | DeleteSource SourceId
    | ProjectDirty Bool
    | DownloadFile FileName FileContent
    | CopyToClipboard String
    | GetLocalFile String File
    | GetDatabaseSchema DatabaseUrl
    | GetTableStats SourceId DatabaseUrl TableId
    | GetColumnStats SourceId DatabaseUrl ColumnRef
    | RunDatabaseQuery String SourceId DatabaseUrl SqlQueryOrigin
    | GetAmlSchema SourceId String
    | GetPrismaSchema String
    | GetCode Dialect JsonSchema
    | GetAutoLayout AutoLayoutMethod Area (List DiagramNode) (List DiagramEdge)
    | ObserveSizes (List HtmlId)
    | LlmGenerateSql OpenAIKey OpenAIModel DatabaseKind Source String
    | LlmLayoutPrompt OpenAIKey OpenAIModel (List Table) String
    | LlmLayoutFromSql OpenAIKey OpenAIModel (List Table) String
    | ListenKeys (Dict String (List Hotkey))
    | Confetti HtmlId
    | ConfettiPride
    | Fireworks
    | Track TrackEvent


type JsMsg
    = GotSizes (List SizeChange)
    | GotProject String (Maybe (Result Decode.Error Project))
    | ProjectDeleted ProjectId
    | GotLocalFile String File FileContent
    | GotDatabaseSchema JsonSchema
    | GotDatabaseSchemaError String
    | GotTableStats SourceId TableStats
    | GotTableStatsError SourceId TableId String
    | GotColumnStats SourceId ColumnStats
    | GotColumnStatsError SourceId ColumnRef String
    | GotDatabaseQueryResult QueryResult
    | GotAmlSchema SourceId Int (Maybe JsonSchema) (List ParserError)
    | GotPrismaSchema JsonSchema
    | GotPrismaSchemaError String
    | GotCode Dialect String
    | GotAutoLayout (List DiagramNode)
    | GotHotkey String
    | GotKeyHold String Bool
    | GotToast String String
    | GotTableShow TableId (Maybe Position.Grid)
    | GotTablesShow String (List { id : TableId, columns : List ColumnName })
    | GotTableHide TableId
    | GotTableToggleColumns TableId
    | GotTablePosition TableId Position.Grid
    | GotTableMove TableId Delta
    | GotTableSelect TableId
    | GotTableColor TableId Color
    | GotColumnShow ColumnRef
    | GotColumnHide ColumnRef
    | GotColumnMove ColumnRef Int
    | GotFitToScreen
    | GotLlmSqlGenerated SqlQuery
    | GotLlmSqlGeneratedError String
    | Error Value Decode.Error


messageToJs : ElmMsg -> Cmd msg
messageToJs message =
    elmToJs (elmEncoder message)


onJsMessage : (JsMsg -> msg) -> Sub msg
onJsMessage callback =
    jsToElm
        (\value ->
            case Decode.decodeValue jsDecoder value of
                Ok message ->
                    callback message

                Err error ->
                    callback (Error value error)
        )


elmEncoder : ElmMsg -> Value
elmEncoder elm =
    case elm of
        Click id ->
            Encode.object [ ( "kind", "Click" |> Encode.string ), ( "id", id |> Encode.string ) ]

        MouseDown id ->
            Encode.object [ ( "kind", "MouseDown" |> Encode.string ), ( "id", id |> Encode.string ) ]

        Focus id ->
            Encode.object [ ( "kind", "Focus" |> Encode.string ), ( "id", id |> Encode.string ) ]

        Blur id ->
            Encode.object [ ( "kind", "Blur" |> Encode.string ), ( "id", id |> Encode.string ) ]

        ScrollTo id position ->
            Encode.object [ ( "kind", "ScrollTo" |> Encode.string ), ( "id", id |> Encode.string ), ( "position", position |> Encode.string ) ]

        Fullscreen id ->
            Encode.notNullObject [ ( "kind", "Fullscreen" |> Encode.string ), ( "id", id |> Encode.maybe Encode.string ) ]

        SetMeta meta ->
            Encode.object
                [ ( "kind", "SetMeta" |> Encode.string )
                , ( "title", meta.title |> Encode.maybe Encode.string )
                , ( "description", meta.description |> Encode.maybe Encode.string )
                , ( "canonical", meta.canonical |> Maybe.map Route.toUrl |> Encode.maybe Encode.string )
                , ( "html", meta.html |> Encode.maybe Encode.string )
                , ( "body", meta.body |> Encode.maybe Encode.string )
                ]

        AutofocusWithin id ->
            Encode.object [ ( "kind", "AutofocusWithin" |> Encode.string ), ( "id", id |> Encode.string ) ]

        Toast level message ->
            Encode.object [ ( "kind", "Toast" |> Encode.string ), ( "level", level |> Encode.string ), ( "message", message |> Encode.string ) ]

        GetProject organization project token ->
            Encode.object [ ( "kind", "GetProject" |> Encode.string ), ( "organization", organization |> OrganizationId.encode ), ( "project", project |> ProjectId.encode ), ( "token", token |> Encode.maybe ProjectTokenId.encode ) ]

        CreateProjectTmp project ->
            Encode.object [ ( "kind", "CreateProjectTmp" |> Encode.string ), ( "project", project |> Project.encode ) ]

        UpdateProjectTmp project ->
            Encode.object [ ( "kind", "UpdateProjectTmp" |> Encode.string ), ( "project", project |> Project.encode ) ]

        CreateProject organization storage project ->
            Encode.object [ ( "kind", "CreateProject" |> Encode.string ), ( "organization", organization |> OrganizationId.encode ), ( "storage", storage |> ProjectStorage.encode ), ( "project", project |> Project.encode ) ]

        UpdateProject project ->
            Encode.object [ ( "kind", "UpdateProject" |> Encode.string ), ( "project", project |> Project.encode ) ]

        MoveProjectTo project storage ->
            Encode.object [ ( "kind", "MoveProjectTo" |> Encode.string ), ( "project", project |> Project.encode ), ( "storage", storage |> ProjectStorage.encode ) ]

        DeleteProject project redirect ->
            Encode.object [ ( "kind", "DeleteProject" |> Encode.string ), ( "project", project |> ProjectInfo.encode ), ( "redirect", redirect |> Encode.maybe Encode.string ) ]

        DeleteSource source ->
            Encode.object [ ( "kind", "DeleteSource" |> Encode.string ), ( "source", source |> SourceId.encode ) ]

        ProjectDirty dirty ->
            Encode.object [ ( "kind", "ProjectDirty" |> Encode.string ), ( "dirty", dirty |> Encode.bool ) ]

        DownloadFile filename content ->
            Encode.object [ ( "kind", "DownloadFile" |> Encode.string ), ( "filename", filename |> Encode.string ), ( "content", content |> Encode.string ) ]

        CopyToClipboard content ->
            Encode.object [ ( "kind", "CopyToClipboard" |> Encode.string ), ( "content", content |> Encode.string ) ]

        GetLocalFile sourceKind file ->
            Encode.object [ ( "kind", "GetLocalFile" |> Encode.string ), ( "sourceKind", sourceKind |> Encode.string ), ( "file", file |> FileValue.encode ) ]

        GetDatabaseSchema database ->
            Encode.object [ ( "kind", "GetDatabaseSchema" |> Encode.string ), ( "database", database |> DatabaseUrl.encode ) ]

        GetTableStats source database table ->
            Encode.object [ ( "kind", "GetTableStats" |> Encode.string ), ( "source", source |> SourceId.encode ), ( "database", database |> DatabaseUrl.encode ), ( "table", table |> TableId.encode ) ]

        GetColumnStats source database column ->
            Encode.object [ ( "kind", "GetColumnStats" |> Encode.string ), ( "source", source |> SourceId.encode ), ( "database", database |> DatabaseUrl.encode ), ( "column", column |> ColumnRef.encode ) ]

        RunDatabaseQuery context source database query ->
            Encode.object [ ( "kind", "RunDatabaseQuery" |> Encode.string ), ( "context", context |> Encode.string ), ( "source", source |> SourceId.encode ), ( "database", database |> DatabaseUrl.encode ), ( "query", query |> SqlQuery.encodeOrigin ) ]

        GetAmlSchema source content ->
            Encode.object [ ( "kind", "GetAmlSchema" |> Encode.string ), ( "source", source |> SourceId.encode ), ( "content", content |> Encode.string ) ]

        GetPrismaSchema content ->
            Encode.object [ ( "kind", "GetPrismaSchema" |> Encode.string ), ( "content", content |> Encode.string ) ]

        GetCode dialect schema ->
            Encode.object [ ( "kind", "GetCode" |> Encode.string ), ( "dialect", dialect |> Dialect.encode ), ( "schema", schema |> JsonSchema.encode ) ]

        GetAutoLayout method viewport nodes edges ->
            Encode.object [ ( "kind", "GetAutoLayout" |> Encode.string ), ( "method", method |> encodeAutoLayoutMethod ), ( "viewport", viewport |> Area.encode ), ( "nodes", nodes |> Encode.list encodeDiagramNode ), ( "edges", edges |> Encode.list encodeDiagramEdge ) ]

        ObserveSizes ids ->
            Encode.object [ ( "kind", "ObserveSizes" |> Encode.string ), ( "ids", ids |> Encode.list Encode.string ) ]

        LlmGenerateSql apiKey model dialect source prompt ->
            Encode.object [ ( "kind", "LlmGenerateSql" |> Encode.string ), ( "apiKey", apiKey |> OpenAIKey.encode ), ( "model", model |> OpenAIModel.encode ), ( "dialect", dialect |> DatabaseKind.encode ), ( "source", source |> Source.encode ), ( "prompt", prompt |> Encode.string ) ]

        LlmLayoutPrompt apiKey model tables prompt ->
            Encode.object [ ( "kind", "LlmLayoutPrompt" |> Encode.string ), ( "apiKey", apiKey |> OpenAIKey.encode ), ( "model", model |> OpenAIModel.encode ), ( "tables", tables |> Encode.list Table.encode ), ( "prompt", prompt |> Encode.string ) ]

        LlmLayoutFromSql apiKey model tables sql ->
            Encode.object [ ( "kind", "LlmLayoutFromSql" |> Encode.string ), ( "apiKey", apiKey |> OpenAIKey.encode ), ( "model", model |> OpenAIModel.encode ), ( "tables", tables |> Encode.list Table.encode ), ( "sql", sql |> Encode.string ) ]

        ListenKeys keys ->
            Encode.object [ ( "kind", "ListenKeys" |> Encode.string ), ( "keys", keys |> Encode.dict identity (Encode.list Hotkey.encode) ) ]

        Confetti id ->
            Encode.object [ ( "kind", "Confetti" |> Encode.string ), ( "id", id |> Encode.string ) ]

        ConfettiPride ->
            Encode.object [ ( "kind", "ConfettiPride" |> Encode.string ) ]

        Fireworks ->
            Encode.object [ ( "kind", "Fireworks" |> Encode.string ) ]

        Track event ->
            Encode.object [ ( "kind", "Track" |> Encode.string ), ( "event", event |> TrackEvent.encode ) ]


jsDecoder : Decoder JsMsg
jsDecoder =
    Decode.matchOn "kind"
        (\kind ->
            case kind of
                "GotSizes" ->
                    Decode.map GotSizes
                        (Decode.field "sizes"
                            (Decode.map4 SizeChange
                                (Decode.field "id" Decode.string)
                                (Decode.field "position" Position.decodeViewport)
                                (Decode.field "size" Size.decodeViewport)
                                (Decode.field "seeds" Delta.decode)
                                |> Decode.list
                            )
                        )

                "GotProject" ->
                    Decode.map2 GotProject (Decode.field "context" Decode.string) (Decode.maybeField "project" projectDecoder)

                "ProjectDeleted" ->
                    Decode.map ProjectDeleted (Decode.field "id" ProjectId.decode)

                "GotLocalFile" ->
                    Decode.map3 GotLocalFile
                        (Decode.field "sourceKind" Decode.string)
                        (Decode.field "file" FileValue.decoder)
                        (Decode.field "content" Decode.string)

                "GotDatabaseSchema" ->
                    Decode.map GotDatabaseSchema (Decode.field "schema" JsonSchema.decode)

                "GotDatabaseSchemaError" ->
                    Decode.map GotDatabaseSchemaError (Decode.field "error" Decode.string)

                "GotTableStats" ->
                    Decode.map2 GotTableStats (Decode.field "source" SourceId.decode) (Decode.field "stats" TableStats.decode)

                "GotTableStatsError" ->
                    Decode.map3 GotTableStatsError (Decode.field "source" SourceId.decode) (Decode.field "table" TableId.decode) (Decode.field "error" Decode.string)

                "GotColumnStats" ->
                    Decode.map2 GotColumnStats (Decode.field "source" SourceId.decode) (Decode.field "stats" ColumnStats.decode)

                "GotColumnStatsError" ->
                    Decode.map3 GotColumnStatsError (Decode.field "source" SourceId.decode) (Decode.field "column" ColumnRef.decode) (Decode.field "error" Decode.string)

                "GotDatabaseQueryResult" ->
                    Decode.map GotDatabaseQueryResult QueryResult.decode

                "GotAmlSchema" ->
                    Decode.map4 GotAmlSchema (Decode.field "source" SourceId.decode) (Decode.field "length" Decode.int) (Decode.maybeField "schema" JsonSchema.decode) (Decode.field "errors" (Decode.list ParserError.decode))

                "GotPrismaSchema" ->
                    Decode.map GotPrismaSchema (Decode.field "schema" JsonSchema.decode)

                "GotPrismaSchemaError" ->
                    Decode.map GotPrismaSchemaError (Decode.field "error" Decode.string)

                "GotCode" ->
                    Decode.map2 GotCode (Decode.field "dialect" Dialect.decode) (Decode.field "content" Decode.string)

                "GotAutoLayout" ->
                    Decode.map GotAutoLayout (Decode.field "nodes" (Decode.list decodeDiagramNode))

                "GotHotkey" ->
                    Decode.map GotHotkey (Decode.field "id" Decode.string)

                "GotKeyHold" ->
                    Decode.map2 GotKeyHold (Decode.field "key" Decode.string) (Decode.field "start" Decode.bool)

                "GotToast" ->
                    Decode.map2 GotToast (Decode.field "level" Decode.string) (Decode.field "message" Decode.string)

                "GotTableShow" ->
                    Decode.map2 GotTableShow (Decode.field "id" TableId.decode) (Decode.maybeField "position" Position.decodeGrid)

                "GotTablesShow" ->
                    Decode.map2 GotTablesShow
                        (Decode.field "from" Decode.string)
                        (Decode.field "tables"
                            (Decode.list
                                (Decode.map2 (\id columns -> { id = id, columns = columns })
                                    (Decode.field "id" TableId.decode)
                                    (Decode.field "columns" (Decode.list ColumnName.decode))
                                )
                            )
                        )

                "GotTableHide" ->
                    Decode.map GotTableHide (Decode.field "id" TableId.decode)

                "GotTableToggleColumns" ->
                    Decode.map GotTableToggleColumns (Decode.field "id" TableId.decode)

                "GotTablePosition" ->
                    Decode.map2 GotTablePosition (Decode.field "id" TableId.decode) (Decode.field "position" Position.decodeGrid)

                "GotTableMove" ->
                    Decode.map2 GotTableMove (Decode.field "id" TableId.decode) (Decode.field "delta" Delta.decode)

                "GotTableSelect" ->
                    Decode.map GotTableSelect (Decode.field "id" TableId.decode)

                "GotTableColor" ->
                    Decode.map2 GotTableColor
                        (Decode.field "id" TableId.decode)
                        (Decode.field "color" Color.decodeColor)

                "GotColumnShow" ->
                    Decode.map GotColumnShow (Decode.field "ref" Decode.string |> Decode.map ColumnRef.fromString)

                "GotColumnHide" ->
                    Decode.map GotColumnHide (Decode.field "ref" Decode.string |> Decode.map ColumnRef.fromString)

                "GotColumnMove" ->
                    Decode.map2 GotColumnMove (Decode.field "ref" Decode.string |> Decode.map ColumnRef.fromString) (Decode.field "index" Decode.int)

                "GotFitToScreen" ->
                    Decode.succeed GotFitToScreen

                "GotLlmSqlGenerated" ->
                    Decode.map GotLlmSqlGenerated (Decode.field "query" Decode.string)

                "GotLlmSqlGeneratedError" ->
                    Decode.map GotLlmSqlGeneratedError (Decode.field "error" Decode.string)

                other ->
                    Decode.fail ("Not supported kind of JsMsg '" ++ other ++ "'")
        )


projectDecoder : Decoder (Result Decode.Error Project)
projectDecoder =
    Decode.map (Decode.decodeValue decodeProject) Decode.value


unhandledJsMsgError : JsMsg -> String
unhandledJsMsgError msg =
    "Unhandled JsMessage: "
        ++ (case msg of
                GotSizes _ ->
                    "GotSizes"

                GotProject _ _ ->
                    "GotProject"

                ProjectDeleted _ ->
                    "ProjectDeleted"

                GotLocalFile _ _ _ ->
                    "GotLocalFile"

                GotDatabaseSchema _ ->
                    "GotDatabaseSchema"

                GotDatabaseSchemaError _ ->
                    "GotDatabaseSchemaError"

                GotTableStats _ _ ->
                    "GotTableStats"

                GotTableStatsError _ _ _ ->
                    "GotTableStatsError"

                GotColumnStats _ _ ->
                    "GotColumnStats"

                GotColumnStatsError _ _ _ ->
                    "GotColumnStatsError"

                GotDatabaseQueryResult _ ->
                    "GotDatabaseQueryResult"

                GotAmlSchema _ _ _ _ ->
                    "GotAmlSchema"

                GotPrismaSchema _ ->
                    "GotPrismaSchema"

                GotPrismaSchemaError _ ->
                    "GotPrismaSchemaError"

                GotCode _ _ ->
                    "GotCode"

                GotAutoLayout _ ->
                    "GotAutoLayout"

                GotHotkey _ ->
                    "GotHotkey"

                GotKeyHold _ _ ->
                    "GotKeyHold"

                GotToast _ _ ->
                    "GotToast"

                GotTableShow _ _ ->
                    "GotTableShow"

                GotTablesShow _ _ ->
                    "GotTablesShow"

                GotTableHide _ ->
                    "GotTableHide"

                GotTableToggleColumns _ ->
                    "GotTableToggleColumns"

                GotTablePosition _ _ ->
                    "GotTablePosition"

                GotTableMove _ _ ->
                    "GotTableMove"

                GotTableSelect _ ->
                    "GotTableSelect"

                GotTableColor _ _ ->
                    "GotTableColor"

                GotColumnShow _ ->
                    "GotColumnShow"

                GotColumnHide _ ->
                    "GotColumnHide"

                GotColumnMove _ _ ->
                    "GotColumnMove"

                GotFitToScreen ->
                    "GotFitToScreen"

                GotLlmSqlGenerated _ ->
                    "GotLlmSqlGenerated"

                GotLlmSqlGeneratedError _ ->
                    "GotLlmSqlGeneratedError"

                Error _ _ ->
                    "Error"
           )


port elmToJs : Value -> Cmd msg


port jsToElm : (Value -> msg) -> Sub msg
