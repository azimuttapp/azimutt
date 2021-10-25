module Storage.ProjectV1 exposing (CanvasProps, Check, CheckName, Column, ColumnIndex, ColumnName, ColumnRef, ColumnType, ColumnValue, Comment, FindPathSettings, Index, IndexName, Layout, LayoutName, PrimaryKey, PrimaryKeyName, Project, ProjectId, ProjectName, ProjectSettings, ProjectSource, ProjectSourceContent(..), ProjectSourceId, ProjectSourceName, Relation, RelationName, SampleName, Schema, SchemaName, Source, SourceLine, Table, TableId, TableName, TableProps, Unique, UniqueName, decodeProject, defaultProjectSettings, upgrade)

import Array
import Conf exposing (conf)
import Dict exposing (Dict)
import Json.Decode as Decode
import Libs.Dict as D
import Libs.Json.Decode as D
import Libs.Json.Formats exposing (decodeColor, decodePosition, decodePosix, decodeZoomLevel)
import Libs.Maybe as M
import Libs.Models exposing (Color, UID, ZoomLevel)
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel exposing (Nel)
import Libs.Position exposing (Position)
import Models.Project as ProjectV2
import Time


type alias Project =
    { id : ProjectId
    , name : ProjectName
    , sources : Nel ProjectSource
    , schema : Schema
    , layouts : Dict LayoutName Layout
    , currentLayout : Maybe LayoutName
    , settings : ProjectSettings
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    , fromSample : Maybe SampleName
    }


type alias ProjectSource =
    -- file the project depend on, they can be refreshed over time
    { id : ProjectSourceId
    , name : ProjectSourceName
    , source : ProjectSourceContent
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


type ProjectSourceContent
    = LocalFile String Int Time.Posix
    | RemoteFile String Int


type alias Schema =
    { tables : Dict TableId Table, relations : List Relation, layout : Layout }


type alias Table =
    { id : TableId
    , schema : SchemaName
    , name : TableName
    , columns : Ned ColumnName Column
    , primaryKey : Maybe PrimaryKey
    , uniques : List Unique
    , indexes : List Index
    , checks : List Check
    , comment : Maybe Comment
    , sources : List Source
    }


type alias Column =
    { index : ColumnIndex
    , name : ColumnName
    , kind : ColumnType
    , nullable : Bool
    , default : Maybe ColumnValue
    , comment : Maybe Comment
    , sources : List Source
    }


type alias PrimaryKey =
    { name : PrimaryKeyName, columns : Nel ColumnName, sources : List Source }


type alias Unique =
    { name : UniqueName, columns : Nel ColumnName, definition : String, sources : List Source }


type alias Index =
    { name : IndexName, columns : Nel ColumnName, definition : String, sources : List Source }


type alias Check =
    { name : CheckName, columns : List ColumnName, predicate : String, sources : List Source }


type alias Comment =
    { text : String, sources : List Source }


type alias Relation =
    { name : RelationName, src : ColumnRef, ref : ColumnRef, sources : List Source }


type alias ColumnRef =
    { table : TableId, column : ColumnName }


type alias Source =
    { id : ProjectSourceId, lines : Nel SourceLine }


type alias SourceLine =
    { no : Int, text : String }


type alias Layout =
    { canvas : CanvasProps
    , tables : List TableProps
    , hiddenTables : List TableProps
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


type alias CanvasProps =
    { position : Position, zoom : ZoomLevel }


type alias TableProps =
    { id : TableId, position : Position, color : Color, columns : List ColumnName, selected : Bool }


type alias ProjectSettings =
    { findPath : FindPathSettings }


type alias FindPathSettings =
    { maxPathLength : Int, ignoredTables : List TableId, ignoredColumns : List ColumnName }


type alias ProjectId =
    UID


type alias ProjectName =
    String


type alias ProjectSourceId =
    UID


type alias ProjectSourceName =
    String


type alias TableId =
    ( SchemaName, TableName )


type alias SchemaName =
    String


type alias TableName =
    String


type alias ColumnName =
    String


type alias ColumnIndex =
    Int


type alias ColumnType =
    String


type alias ColumnValue =
    String


type alias PrimaryKeyName =
    String


type alias UniqueName =
    String


type alias IndexName =
    String


type alias CheckName =
    String


type alias RelationName =
    String


type alias LayoutName =
    String


type alias SampleName =
    String


stringAsTableId : String -> TableId
stringAsTableId id =
    case String.split "." id of
        schema :: table :: [] ->
            ( schema, table )

        _ ->
            ( conf.default.schema, id )


stringAsLayoutName : String -> LayoutName
stringAsLayoutName name =
    name


initLayout : Time.Posix -> Layout
initLayout now =
    { canvas = CanvasProps (Position 0 0) 1, tables = [], hiddenTables = [], createdAt = now, updatedAt = now }


defaultTime : Time.Posix
defaultTime =
    Time.millisToPosix 0


defaultLayout : Layout
defaultLayout =
    initLayout defaultTime


defaultProjectSettings : { findPath : FindPathSettings }
defaultProjectSettings =
    { findPath = FindPathSettings 3 [] [] }



-- UPGRADE


upgrade : Project -> ProjectV2.Project
upgrade project =
    { id = project.id
    , name = project.name
    , sources = project.sources |> Nel.toList |> List.map (upgradeProjectSource project.schema.tables project.schema.relations project.fromSample)
    , tables = project.schema.tables |> Dict.map (\_ -> upgradeTable)
    , relations = project.schema.relations |> List.map upgradeRelation
    , layout = project.schema.layout
    , usedLayout = project.currentLayout
    , layouts = project.layouts
    , settings = project.settings
    , createdAt = project.createdAt
    , updatedAt = project.updatedAt
    }


upgradeProjectSource : Dict TableId Table -> List Relation -> Maybe SampleName -> ProjectSource -> ProjectV2.Source
upgradeProjectSource tables relations fromSample source =
    { id = source.id
    , name = source.name
    , kind =
        case source.source of
            LocalFile name size modified ->
                ProjectV2.LocalFile name size modified

            RemoteFile url size ->
                ProjectV2.RemoteFile url size
    , content =
        let
            sources : Dict Int String
            sources =
                tables |> Dict.values |> List.concatMap .sources |> List.concatMap (\s -> s.lines |> Nel.toList) |> List.map (\s -> ( s.no, s.text )) |> Dict.fromList

            max : Int
            max =
                sources |> Dict.keys |> List.maximum |> M.mapOrElse (\i -> i + 1) 0
        in
        List.repeat max "" |> List.indexedMap (\i a -> sources |> D.getOrElse i a) |> Array.fromList
    , tables = tables |> Dict.map (\_ -> upgradeTable)
    , relations = relations |> List.map upgradeRelation
    , enabled = True
    , fromSample = fromSample
    , createdAt = source.createdAt
    , updatedAt = source.updatedAt
    }


upgradeTable : Table -> ProjectV2.Table
upgradeTable table =
    { id = table.id
    , schema = table.schema
    , name = table.name
    , columns = table.columns |> Ned.map (\_ -> upgradeColumn)
    , primaryKey = table.primaryKey |> Maybe.map upgradePrimaryKey
    , uniques = table.uniques |> List.map upgradeUnique
    , indexes = table.indexes |> List.map upgradeIndex
    , checks = table.checks |> List.map upgradeCheck
    , comment = table.comment |> Maybe.map upgradeComment
    , origins = table.sources |> List.map upgradeSource
    }


upgradeColumn : Column -> ProjectV2.Column
upgradeColumn column =
    { index = column.index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment |> Maybe.map upgradeComment
    , origins = column.sources |> List.map upgradeSource
    }


upgradePrimaryKey : PrimaryKey -> ProjectV2.PrimaryKey
upgradePrimaryKey pk =
    { name = pk.name, columns = pk.columns, origins = pk.sources |> List.map upgradeSource }


upgradeUnique : Unique -> ProjectV2.Unique
upgradeUnique unique =
    { name = unique.name, columns = unique.columns, definition = unique.definition, origins = unique.sources |> List.map upgradeSource }


upgradeIndex : Index -> ProjectV2.Index
upgradeIndex index =
    { name = index.name, columns = index.columns, definition = index.definition, origins = index.sources |> List.map upgradeSource }


upgradeCheck : Check -> ProjectV2.Check
upgradeCheck check =
    { name = check.name, columns = check.columns, predicate = check.predicate, origins = check.sources |> List.map upgradeSource }


upgradeComment : Comment -> ProjectV2.Comment
upgradeComment comment =
    { text = comment.text, origins = comment.sources |> List.map upgradeSource }


upgradeRelation : Relation -> ProjectV2.Relation
upgradeRelation relation =
    { name = relation.name, src = relation.src, ref = relation.ref, origins = relation.sources |> List.map upgradeSource }


upgradeSource : Source -> ProjectV2.Origin
upgradeSource source =
    { id = source.id, lines = source.lines |> Nel.toList |> List.map .no }



-- JSON


decodeProject : Decode.Decoder Project
decodeProject =
    D.map10 Project
        (Decode.field "id" decodeProjectId)
        (Decode.field "name" decodeProjectName)
        (Decode.field "sources" (D.nel decodeProjectSource))
        (Decode.field "schema" decodeSchema)
        (D.defaultField "layouts" (D.dict stringAsLayoutName decodeLayout) Dict.empty)
        (D.maybeField "currentLayout" decodeLayoutName)
        (D.defaultFieldDeep "settings" decodeProjectSettings defaultProjectSettings)
        (D.defaultField "createdAt" decodePosix defaultTime)
        (D.defaultField "updatedAt" decodePosix defaultTime)
        (D.maybeField "fromSample" decodeSampleName)


decodeProjectSource : Decode.Decoder ProjectSource
decodeProjectSource =
    Decode.map5 ProjectSource
        (Decode.field "id" decodeProjectSourceId)
        (Decode.field "name" decodeProjectSourceName)
        (Decode.field "source" decodeProjectSourceContent)
        (Decode.field "createdAt" decodePosix)
        (Decode.field "updatedAt" decodePosix)


decodeProjectSourceContent : Decode.Decoder ProjectSourceContent
decodeProjectSourceContent =
    D.matchOn "kind"
        (\kind ->
            case kind of
                "LocalFile" ->
                    Decode.map3 LocalFile
                        (Decode.field "name" Decode.string)
                        (Decode.field "size" Decode.int)
                        (Decode.field "lastModified" decodePosix)

                "RemoteFile" ->
                    Decode.map2 RemoteFile
                        (Decode.field "name" Decode.string)
                        (Decode.field "size" Decode.int)

                other ->
                    Decode.fail ("Not supported kind of ProjectSourceContent '" ++ other ++ "'")
        )


decodeSchema : Decode.Decoder Schema
decodeSchema =
    Decode.map3 Schema
        (Decode.field "tables" (Decode.list decodeTable) |> Decode.map (D.fromListMap .id))
        (Decode.field "relations" (Decode.list decodeRelation))
        (D.defaultField "layout" decodeLayout defaultLayout)


decodeTable : Decode.Decoder Table
decodeTable =
    D.map9 (\s t c p u i ch co so -> Table ( s, t ) s t c p u i ch co so)
        (Decode.field "schema" decodeSchemaName)
        (Decode.field "table" decodeTableName)
        (Decode.field "columns" (D.nel decodeColumn |> Decode.map (Nel.indexedMap (\i c -> c i) >> Ned.fromNelMap .name)))
        (D.maybeField "primaryKey" decodePrimaryKey)
        (D.defaultField "uniques" (Decode.list decodeUnique) [])
        (D.defaultField "indexes" (Decode.list decodeIndex) [])
        (D.defaultField "checks" (Decode.list decodeCheck) [])
        (D.maybeField "comment" decodeComment)
        (D.defaultField "sources" (Decode.list decodeSource) [])


decodeColumn : Decode.Decoder (Int -> Column)
decodeColumn =
    Decode.map6 (\n t nu d c s -> \i -> Column i n t nu d c s)
        (Decode.field "name" decodeColumnName)
        (Decode.field "type" decodeColumnType)
        (D.defaultField "nullable" Decode.bool False)
        (D.maybeField "default" decodeColumnValue)
        (D.maybeField "comment" decodeComment)
        (D.defaultField "sources" (Decode.list decodeSource) [])


decodePrimaryKey : Decode.Decoder PrimaryKey
decodePrimaryKey =
    Decode.map3 PrimaryKey
        (Decode.field "name" decodePrimaryKeyName)
        (Decode.field "columns" (D.nel decodeColumnName))
        (D.defaultField "sources" (Decode.list decodeSource) [])


decodeUnique : Decode.Decoder Unique
decodeUnique =
    Decode.map4 Unique
        (Decode.field "name" decodeUniqueName)
        (Decode.field "columns" (D.nel decodeColumnName))
        (Decode.field "definition" Decode.string)
        (D.defaultField "sources" (Decode.list decodeSource) [])


decodeIndex : Decode.Decoder Index
decodeIndex =
    Decode.map4 Index
        (Decode.field "name" decodeIndexName)
        (Decode.field "columns" (D.nel decodeColumnName))
        (Decode.field "definition" Decode.string)
        (D.defaultField "sources" (Decode.list decodeSource) [])


decodeCheck : Decode.Decoder Check
decodeCheck =
    Decode.map4 Check
        (Decode.field "name" decodeCheckName)
        (D.defaultField "columns" (Decode.list decodeColumnName) [])
        (Decode.field "predicate" Decode.string)
        (D.defaultField "sources" (Decode.list decodeSource) [])


decodeComment : Decode.Decoder Comment
decodeComment =
    Decode.map2 Comment
        (Decode.field "text" Decode.string)
        (D.defaultField "sources" (Decode.list decodeSource) [])


decodeRelation : Decode.Decoder Relation
decodeRelation =
    Decode.map4 Relation
        (Decode.field "name" decodeRelationName)
        (Decode.field "src" decodeColumnRef)
        (Decode.field "ref" decodeColumnRef)
        (D.defaultField "sources" (Decode.list decodeSource) [])


decodeColumnRef : Decode.Decoder ColumnRef
decodeColumnRef =
    Decode.map2 ColumnRef
        (Decode.field "table" decodeTableId)
        (Decode.field "column" decodeColumnName)


decodeSource : Decode.Decoder Source
decodeSource =
    Decode.map2 Source
        (Decode.field "id" decodeProjectSourceId)
        (Decode.field "lines" (D.nel decodeSourceLine))


decodeSourceLine : Decode.Decoder SourceLine
decodeSourceLine =
    Decode.map2 SourceLine
        (Decode.field "no" Decode.int)
        (Decode.field "text" Decode.string)


decodeLayout : Decode.Decoder Layout
decodeLayout =
    Decode.map5 Layout
        (Decode.field "canvas" decodeCanvasProps)
        (Decode.field "tables" (Decode.list decodeTableProps))
        (D.defaultField "hiddenTables" (Decode.list decodeTableProps) [])
        (Decode.field "createdAt" decodePosix)
        (Decode.field "updatedAt" decodePosix)


decodeCanvasProps : Decode.Decoder CanvasProps
decodeCanvasProps =
    Decode.map2 CanvasProps
        (Decode.field "position" decodePosition)
        (Decode.field "zoom" decodeZoomLevel)


decodeTableProps : Decode.Decoder TableProps
decodeTableProps =
    Decode.map5 TableProps
        (Decode.field "id" decodeTableId)
        (Decode.field "position" decodePosition)
        (Decode.field "color" decodeColor)
        (D.defaultField "columns" (Decode.list decodeColumnName) [])
        (D.defaultField "selected" Decode.bool False)


decodeProjectSettings : ProjectSettings -> Decode.Decoder ProjectSettings
decodeProjectSettings default =
    Decode.map ProjectSettings
        (D.defaultFieldDeep "findPath" decodeFindPathSettings default.findPath)


decodeFindPathSettings : FindPathSettings -> Decode.Decoder FindPathSettings
decodeFindPathSettings default =
    Decode.map3 FindPathSettings
        (D.defaultField "maxPathLength" Decode.int default.maxPathLength)
        (D.defaultField "ignoredTables" (Decode.list decodeTableId) default.ignoredTables)
        (D.defaultField "ignoredColumns" (Decode.list decodeColumnName) default.ignoredColumns)


decodeProjectId : Decode.Decoder ProjectId
decodeProjectId =
    Decode.string


decodeProjectName : Decode.Decoder ProjectName
decodeProjectName =
    Decode.string


decodeProjectSourceId : Decode.Decoder ProjectSourceId
decodeProjectSourceId =
    Decode.string


decodeProjectSourceName : Decode.Decoder ProjectSourceName
decodeProjectSourceName =
    Decode.string


decodeTableId : Decode.Decoder TableId
decodeTableId =
    Decode.string |> Decode.map stringAsTableId


decodeSchemaName : Decode.Decoder SchemaName
decodeSchemaName =
    Decode.string


decodeTableName : Decode.Decoder TableName
decodeTableName =
    Decode.string


decodeColumnName : Decode.Decoder ColumnName
decodeColumnName =
    Decode.string


decodeColumnType : Decode.Decoder ColumnType
decodeColumnType =
    Decode.string


decodeColumnValue : Decode.Decoder ColumnValue
decodeColumnValue =
    Decode.string


decodePrimaryKeyName : Decode.Decoder PrimaryKeyName
decodePrimaryKeyName =
    Decode.string


decodeUniqueName : Decode.Decoder UniqueName
decodeUniqueName =
    Decode.string


decodeIndexName : Decode.Decoder IndexName
decodeIndexName =
    Decode.string


decodeCheckName : Decode.Decoder CheckName
decodeCheckName =
    Decode.string


decodeRelationName : Decode.Decoder RelationName
decodeRelationName =
    Decode.string


decodeLayoutName : Decode.Decoder LayoutName
decodeLayoutName =
    Decode.string


decodeSampleName : Decode.Decoder SampleName
decodeSampleName =
    Decode.string
