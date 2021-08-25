module Models.Project exposing (CanvasProps, Check, CheckName, Column, ColumnIndex, ColumnName, ColumnRef, ColumnRefFull, ColumnType, ColumnValue, Comment, FindPath, FindPathPath, FindPathResult, FindPathSettings, FindPathState(..), FindPathStep, FindPathStepDir(..), Index, IndexName, Layout, LayoutName, PrimaryKey, PrimaryKeyName, Project, ProjectId, ProjectName, ProjectSettings, ProjectSource, ProjectSourceContent(..), ProjectSourceId, ProjectSourceName, Relation, RelationFull, RelationName, Schema, SchemaName, Source, SourceLine, Table, TableId, TableName, TableProps, Unique, UniqueName, buildProject, decodeCanvasProps, decodeCheck, decodeColumn, decodeColumnName, decodeColumnRef, decodeComment, decodeIndex, decodeLayout, decodePrimaryKey, decodeProject, decodeProjectId, decodeProjectName, decodeProjectSettings, decodeProjectSource, decodeProjectSourceContent, decodeProjectSourceId, decodeProjectSourceName, decodeRelation, decodeSchema, decodeSource, decodeSourceLine, decodeTable, decodeTableId, decodeTableProps, decodeUnique, encodeCanvasProps, encodeCheck, encodeColumn, encodeColumnName, encodeColumnRef, encodeComment, encodeIndex, encodeLayout, encodePrimaryKey, encodeProject, encodeProjectId, encodeProjectName, encodeProjectSettings, encodeProjectSource, encodeProjectSourceContent, encodeProjectSourceId, encodeProjectSourceName, encodeRelation, encodeSchema, encodeSource, encodeSourceLine, encodeTable, encodeTableId, encodeTableProps, encodeUnique, extractPath, htmlIdAsTableId, inIndexes, inOutRelation, inPrimaryKey, inUniques, initLayout, initTableProps, parseTableId, showColumnRef, showTableId, showTableName, stringAsTableId, tableIdAsHtmlId, tableIdAsString, tablesArea, viewportArea, viewportSize, withNullableInfo)

import Conf exposing (conf)
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Area exposing (Area)
import Libs.Dict as D
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Json.Formats exposing (decodeColor, decodePosition, decodePosix, decodeZoomLevel, encodeColor, encodePosition, encodePosix, encodeZoomLevel)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (Color, HtmlId, UID, ZoomLevel)
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel exposing (Nel)
import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Libs.String as S
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
    { name : CheckName, predicate : String, sources : List Source }


type alias Comment =
    { text : String, sources : List Source }


type alias Relation =
    { name : RelationName, src : ColumnRef, ref : ColumnRef, sources : List Source }


type alias ColumnRef =
    { table : TableId, column : ColumnName }


type alias RelationFull =
    { name : RelationName, src : ColumnRefFull, ref : ColumnRefFull, sources : List Source }


type alias ColumnRefFull =
    { ref : ColumnRef, table : Table, column : Column, props : Maybe ( TableProps, Int, Size ) }


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


type alias FindPath =
    { from : Maybe TableId
    , to : Maybe TableId
    , result : FindPathState
    }


type FindPathState
    = Empty
    | Searching
    | Found FindPathResult


type alias FindPathResult =
    { from : TableId
    , to : TableId
    , paths : List FindPathPath
    , settings : FindPathSettings
    }


type alias FindPathPath =
    Nel FindPathStep


type alias FindPathStep =
    { relation : Relation, direction : FindPathStepDir }


type FindPathStepDir
    = Right
    | Left


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


buildProject : ProjectId -> ProjectName -> Nel ProjectSource -> Schema -> Time.Posix -> Project
buildProject id name sources schema now =
    { id = id
    , name = name
    , sources = sources
    , schema = schema
    , layouts = Dict.empty
    , currentLayout = Nothing
    , settings = defaultProjectSettings
    , createdAt = now
    , updatedAt = now
    }


tableIdAsHtmlId : TableId -> HtmlId
tableIdAsHtmlId ( schema, table ) =
    "table-" ++ schema ++ "-" ++ table


htmlIdAsTableId : HtmlId -> TableId
htmlIdAsTableId id =
    case String.split "-" id of
        "table" :: schema :: table :: [] ->
            ( schema, table )

        _ ->
            ( conf.default.schema, id )


tableIdAsString : TableId -> String
tableIdAsString ( schema, table ) =
    schema ++ "." ++ table


stringAsTableId : String -> TableId
stringAsTableId id =
    case String.split "." id of
        schema :: table :: [] ->
            ( schema, table )

        _ ->
            ( conf.default.schema, id )


layoutNameAsString : LayoutName -> String
layoutNameAsString name =
    name


stringAsLayoutName : String -> LayoutName
stringAsLayoutName name =
    name


showTableName : SchemaName -> TableName -> String
showTableName schema table =
    if schema == conf.default.schema then
        table

    else
        schema ++ "." ++ table


showTableId : TableId -> String
showTableId ( schema, table ) =
    showTableName schema table


parseTableId : String -> TableId
parseTableId tableId =
    case tableId |> String.split "." of
        table :: [] ->
            ( conf.default.schema, table )

        schema :: table :: [] ->
            ( schema, table )

        _ ->
            ( conf.default.schema, tableId )


showColumnRef : ColumnRef -> String
showColumnRef ref =
    showTableId ref.table ++ "." ++ ref.column


extractPath : ProjectSourceContent -> String
extractPath sourceContent =
    case sourceContent of
        LocalFile path _ _ ->
            path

        RemoteFile url _ ->
            url


initLayout : Time.Posix -> Layout
initLayout now =
    { canvas = CanvasProps (Position 0 0) 1, tables = [], hiddenTables = [], createdAt = now, updatedAt = now }


initTableProps : Table -> TableProps
initTableProps table =
    { id = table.id
    , position = Position 0 0
    , color = computeColor table.id
    , selected = False
    , columns = table.columns |> Ned.values |> Nel.toList |> List.sortBy .index |> List.map .name
    }


computeColor : TableId -> Color
computeColor ( _, table ) =
    S.wordSplit table
        |> List.head
        |> Maybe.map S.hashCode
        |> Maybe.map (modBy (List.length conf.colors))
        |> Maybe.andThen (\index -> conf.colors |> L.get index)
        |> Maybe.withDefault conf.default.color


inPrimaryKey : Table -> ColumnName -> Maybe PrimaryKey
inPrimaryKey table column =
    table.primaryKey |> M.filter (\{ columns } -> columns |> hasColumn column)


inUniques : Table -> ColumnName -> List Unique
inUniques table column =
    table.uniques |> List.filter (\u -> u.columns |> hasColumn column)


inIndexes : Table -> ColumnName -> List Index
inIndexes table column =
    table.indexes |> List.filter (\i -> i.columns |> hasColumn column)


hasColumn : ColumnName -> Nel ColumnName -> Bool
hasColumn column columns =
    columns |> Nel.any (\c -> c == column)


inOutRelation : List Relation -> ColumnName -> List Relation
inOutRelation tableOutRelations column =
    tableOutRelations |> List.filter (\r -> r.src.column == column)


withNullableInfo : Bool -> String -> String
withNullableInfo nullable text =
    if nullable then
        text ++ "?"

    else
        text


viewportSize : Dict HtmlId Size -> Maybe Size
viewportSize sizes =
    sizes |> Dict.get conf.ids.erd


viewportArea : Size -> CanvasProps -> Area
viewportArea size canvas =
    let
        left : Float
        left =
            -canvas.position.left / canvas.zoom

        top : Float
        top =
            -canvas.position.top / canvas.zoom

        right : Float
        right =
            (-canvas.position.left + size.width) / canvas.zoom

        bottom : Float
        bottom =
            (-canvas.position.top + size.height) / canvas.zoom
    in
    Area left top right bottom


tablesArea : Dict HtmlId Size -> List TableProps -> Area
tablesArea sizes tables =
    let
        positions : List ( TableProps, Size )
        positions =
            tables |> L.zipWith (\t -> sizes |> Dict.get (tableIdAsHtmlId t.id) |> Maybe.withDefault (Size 0 0))

        left : Float
        left =
            positions |> List.map (\( t, _ ) -> t.position.left) |> List.minimum |> Maybe.withDefault 0

        top : Float
        top =
            positions |> List.map (\( t, _ ) -> t.position.top) |> List.minimum |> Maybe.withDefault 0

        right : Float
        right =
            positions |> List.map (\( t, s ) -> t.position.left + s.width) |> List.maximum |> Maybe.withDefault 0

        bottom : Float
        bottom =
            positions |> List.map (\( t, s ) -> t.position.top + s.height) |> List.maximum |> Maybe.withDefault 0
    in
    Area left top right bottom


defaultTime : Time.Posix
defaultTime =
    Time.millisToPosix 0


defaultLayout : Layout
defaultLayout =
    initLayout defaultTime


defaultProjectSettings : { findPath : FindPathSettings }
defaultProjectSettings =
    { findPath = FindPathSettings 3 [] [] }



-- JSON


currentVersion : Int
currentVersion =
    -- compatibility version for Project JSON, when you have breaking change, increment it and handle needed migrations
    1


encodeProject : Project -> Value
encodeProject value =
    E.object
        [ ( "id", value.id |> encodeProjectId )
        , ( "name", value.name |> encodeProjectName )
        , ( "sources", value.sources |> E.nel encodeProjectSource )
        , ( "schema", value.schema |> encodeSchema )
        , ( "layouts", value.layouts |> Encode.dict layoutNameAsString encodeLayout )
        , ( "currentLayout", value.currentLayout |> E.maybe encodeLayoutName )
        , ( "settings", value.settings |> E.withDefaultDeep encodeProjectSettings defaultProjectSettings )
        , ( "createdAt", value.createdAt |> encodePosix )
        , ( "updatedAt", value.updatedAt |> encodePosix )
        , ( "version", currentVersion |> Encode.int )
        ]


decodeProject : Decode.Decoder Project
decodeProject =
    D.map9 Project
        (Decode.field "id" decodeProjectId)
        (Decode.field "name" decodeProjectName)
        (Decode.field "sources" (D.nel decodeProjectSource))
        (Decode.field "schema" decodeSchema)
        (D.defaultField "layouts" (D.dict stringAsLayoutName decodeLayout) Dict.empty)
        (D.maybeField "currentLayout" decodeLayoutName)
        (D.defaultFieldDeep "settings" decodeProjectSettings defaultProjectSettings)
        (D.defaultField "createdAt" decodePosix defaultTime)
        (D.defaultField "updatedAt" decodePosix defaultTime)


encodeProjectSource : ProjectSource -> Value
encodeProjectSource value =
    E.object
        [ ( "id", value.id |> encodeProjectSourceId )
        , ( "name", value.name |> encodeProjectSourceName )
        , ( "source", value.source |> encodeProjectSourceContent )
        , ( "createdAt", value.createdAt |> encodePosix )
        , ( "updatedAt", value.updatedAt |> encodePosix )
        ]


decodeProjectSource : Decode.Decoder ProjectSource
decodeProjectSource =
    Decode.map5 ProjectSource
        (Decode.field "id" decodeProjectSourceId)
        (Decode.field "name" decodeProjectSourceName)
        (Decode.field "source" decodeProjectSourceContent)
        (Decode.field "createdAt" decodePosix)
        (Decode.field "updatedAt" decodePosix)


encodeProjectSourceContent : ProjectSourceContent -> Value
encodeProjectSourceContent value =
    case value of
        LocalFile name size lastModified ->
            E.object
                [ ( "kind", "LocalFile" |> Encode.string )
                , ( "name", name |> Encode.string )
                , ( "size", size |> Encode.int )
                , ( "lastModified", lastModified |> encodePosix )
                ]

        RemoteFile name size ->
            E.object
                [ ( "kind", "RemoteFile" |> Encode.string )
                , ( "name", name |> Encode.string )
                , ( "size", size |> Encode.int )
                ]


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


encodeSchema : Schema -> Value
encodeSchema value =
    E.object
        [ ( "tables", value.tables |> Dict.values |> Encode.list encodeTable )
        , ( "relations", value.relations |> Encode.list encodeRelation )
        , ( "layout", value.layout |> encodeLayout )
        ]


decodeSchema : Decode.Decoder Schema
decodeSchema =
    Decode.map3 Schema
        (Decode.field "tables" (Decode.list decodeTable) |> Decode.map (D.fromListMap .id))
        (Decode.field "relations" (Decode.list decodeRelation))
        (D.defaultField "layout" decodeLayout defaultLayout)


encodeTable : Table -> Value
encodeTable value =
    E.object
        [ ( "schema", value.schema |> encodeSchemaName )
        , ( "table", value.name |> encodeTableName )
        , ( "columns", value.columns |> Ned.values |> Nel.sortBy .index |> E.nel encodeColumn )
        , ( "primaryKey", value.primaryKey |> E.maybe encodePrimaryKey )
        , ( "uniques", value.uniques |> E.withDefault (Encode.list encodeUnique) [] )
        , ( "indexes", value.indexes |> E.withDefault (Encode.list encodeIndex) [] )
        , ( "checks", value.checks |> E.withDefault (Encode.list encodeCheck) [] )
        , ( "comment", value.comment |> E.maybe encodeComment )
        , ( "sources", value.sources |> E.withDefault (Encode.list encodeSource) [] )
        ]


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


encodeColumn : Column -> Value
encodeColumn value =
    E.object
        [ ( "name", value.name |> encodeColumnName )
        , ( "type", value.kind |> encodeColumnType )
        , ( "nullable", value.nullable |> E.withDefault Encode.bool False )
        , ( "default", value.default |> E.maybe encodeColumnValue )
        , ( "comment", value.comment |> E.maybe encodeComment )
        , ( "sources", value.sources |> E.withDefault (Encode.list encodeSource) [] )
        ]


decodeColumn : Decode.Decoder (Int -> Column)
decodeColumn =
    Decode.map6 (\n t nu d c s -> \i -> Column i n t nu d c s)
        (Decode.field "name" decodeColumnName)
        (Decode.field "type" decodeColumnType)
        (D.defaultField "nullable" Decode.bool False)
        (D.maybeField "default" decodeColumnValue)
        (D.maybeField "comment" decodeComment)
        (D.defaultField "sources" (Decode.list decodeSource) [])


encodePrimaryKey : PrimaryKey -> Value
encodePrimaryKey value =
    E.object
        [ ( "name", value.name |> encodePrimaryKeyName )
        , ( "columns", value.columns |> E.nel encodeColumnName )
        , ( "sources", value.sources |> E.withDefault (Encode.list encodeSource) [] )
        ]


decodePrimaryKey : Decode.Decoder PrimaryKey
decodePrimaryKey =
    Decode.map3 PrimaryKey
        (Decode.field "name" decodePrimaryKeyName)
        (Decode.field "columns" (D.nel decodeColumnName))
        (D.defaultField "sources" (Decode.list decodeSource) [])


encodeUnique : Unique -> Value
encodeUnique value =
    E.object
        [ ( "name", value.name |> encodeUniqueName )
        , ( "columns", value.columns |> E.nel encodeColumnName )
        , ( "definition", value.definition |> Encode.string )
        , ( "sources", value.sources |> E.withDefault (Encode.list encodeSource) [] )
        ]


decodeUnique : Decode.Decoder Unique
decodeUnique =
    Decode.map4 Unique
        (Decode.field "name" decodeUniqueName)
        (Decode.field "columns" (D.nel decodeColumnName))
        (Decode.field "definition" Decode.string)
        (D.defaultField "sources" (Decode.list decodeSource) [])


encodeIndex : Index -> Value
encodeIndex value =
    E.object
        [ ( "name", value.name |> encodeIndexName )
        , ( "columns", value.columns |> E.nel encodeColumnName )
        , ( "definition", value.definition |> Encode.string )
        , ( "sources", value.sources |> E.withDefault (Encode.list encodeSource) [] )
        ]


decodeIndex : Decode.Decoder Index
decodeIndex =
    Decode.map4 Index
        (Decode.field "name" decodeIndexName)
        (Decode.field "columns" (D.nel decodeColumnName))
        (Decode.field "definition" Decode.string)
        (D.defaultField "sources" (Decode.list decodeSource) [])


encodeCheck : Check -> Value
encodeCheck value =
    E.object
        [ ( "name", value.name |> encodeCheckName )
        , ( "predicate", value.predicate |> Encode.string )
        , ( "sources", value.sources |> E.withDefault (Encode.list encodeSource) [] )
        ]


decodeCheck : Decode.Decoder Check
decodeCheck =
    Decode.map3 Check
        (Decode.field "name" decodeCheckName)
        (Decode.field "predicate" Decode.string)
        (D.defaultField "sources" (Decode.list decodeSource) [])


encodeComment : Comment -> Value
encodeComment value =
    E.object
        [ ( "text", value.text |> Encode.string )
        , ( "sources", value.sources |> E.withDefault (Encode.list encodeSource) [] )
        ]


decodeComment : Decode.Decoder Comment
decodeComment =
    Decode.map2 Comment
        (Decode.field "text" Decode.string)
        (D.defaultField "sources" (Decode.list decodeSource) [])


encodeRelation : Relation -> Value
encodeRelation value =
    E.object
        [ ( "name", value.name |> encodeRelationName )
        , ( "src", value.src |> encodeColumnRef )
        , ( "ref", value.ref |> encodeColumnRef )
        , ( "sources", value.sources |> E.withDefault (Encode.list encodeSource) [] )
        ]


decodeRelation : Decode.Decoder Relation
decodeRelation =
    Decode.map4 Relation
        (Decode.field "name" decodeRelationName)
        (Decode.field "src" decodeColumnRef)
        (Decode.field "ref" decodeColumnRef)
        (D.defaultField "sources" (Decode.list decodeSource) [])


encodeColumnRef : ColumnRef -> Value
encodeColumnRef value =
    E.object
        [ ( "table", value.table |> encodeTableId )
        , ( "column", value.column |> encodeColumnName )
        ]


decodeColumnRef : Decode.Decoder ColumnRef
decodeColumnRef =
    Decode.map2 ColumnRef
        (Decode.field "table" decodeTableId)
        (Decode.field "column" decodeColumnName)


encodeSource : Source -> Value
encodeSource value =
    E.object
        [ ( "id", value.id |> encodeProjectSourceId )
        , ( "lines", value.lines |> E.nel encodeSourceLine )
        ]


decodeSource : Decode.Decoder Source
decodeSource =
    Decode.map2 Source
        (Decode.field "id" decodeProjectSourceId)
        (Decode.field "lines" (D.nel decodeSourceLine))


encodeSourceLine : SourceLine -> Value
encodeSourceLine value =
    E.object
        [ ( "no", value.no |> Encode.int )
        , ( "text", value.text |> Encode.string )
        ]


decodeSourceLine : Decode.Decoder SourceLine
decodeSourceLine =
    Decode.map2 SourceLine
        (Decode.field "no" Decode.int)
        (Decode.field "text" Decode.string)


encodeLayout : Layout -> Value
encodeLayout value =
    E.object
        [ ( "canvas", value.canvas |> encodeCanvasProps )
        , ( "tables", value.tables |> Encode.list encodeTableProps )
        , ( "hiddenTables", value.hiddenTables |> E.withDefault (Encode.list encodeTableProps) [] )
        , ( "createdAt", value.createdAt |> encodePosix )
        , ( "updatedAt", value.updatedAt |> encodePosix )
        ]


decodeLayout : Decode.Decoder Layout
decodeLayout =
    Decode.map5 Layout
        (Decode.field "canvas" decodeCanvasProps)
        (Decode.field "tables" (Decode.list decodeTableProps))
        (D.defaultField "hiddenTables" (Decode.list decodeTableProps) [])
        (Decode.field "createdAt" decodePosix)
        (Decode.field "updatedAt" decodePosix)


encodeCanvasProps : CanvasProps -> Value
encodeCanvasProps value =
    E.object
        [ ( "position", value.position |> encodePosition )
        , ( "zoom", value.zoom |> encodeZoomLevel )
        ]


decodeCanvasProps : Decode.Decoder CanvasProps
decodeCanvasProps =
    Decode.map2 CanvasProps
        (Decode.field "position" decodePosition)
        (Decode.field "zoom" decodeZoomLevel)


encodeTableProps : TableProps -> Value
encodeTableProps value =
    E.object
        [ ( "id", value.id |> encodeTableId )
        , ( "position", value.position |> encodePosition )
        , ( "color", value.color |> encodeColor )
        , ( "columns", value.columns |> E.withDefault (Encode.list encodeColumnName) [] )
        , ( "selected", value.selected |> E.withDefault Encode.bool False )
        ]


decodeTableProps : Decode.Decoder TableProps
decodeTableProps =
    Decode.map5 TableProps
        (Decode.field "id" decodeTableId)
        (Decode.field "position" decodePosition)
        (Decode.field "color" decodeColor)
        (D.defaultField "columns" (Decode.list decodeColumnName) [])
        (D.defaultField "selected" Decode.bool False)


encodeProjectSettings : ProjectSettings -> ProjectSettings -> Value
encodeProjectSettings default value =
    E.object [ ( "findPath", value.findPath |> E.withDefaultDeep encodeFindPathSettings default.findPath ) ]


decodeProjectSettings : ProjectSettings -> Decode.Decoder ProjectSettings
decodeProjectSettings default =
    Decode.map ProjectSettings
        (D.defaultFieldDeep "findPath" decodeFindPathSettings default.findPath)


encodeFindPathSettings : FindPathSettings -> FindPathSettings -> Value
encodeFindPathSettings default value =
    E.object
        [ ( "maxPathLength", value.maxPathLength |> E.withDefault Encode.int default.maxPathLength )
        , ( "ignoredTables", value.ignoredTables |> E.withDefault (Encode.list encodeTableId) default.ignoredTables )
        , ( "ignoredColumns", value.ignoredColumns |> E.withDefault (Encode.list encodeColumnName) default.ignoredColumns )
        ]


decodeFindPathSettings : FindPathSettings -> Decode.Decoder FindPathSettings
decodeFindPathSettings default =
    Decode.map3 FindPathSettings
        (D.defaultField "maxPathLength" Decode.int default.maxPathLength)
        (D.defaultField "ignoredTables" (Decode.list decodeTableId) default.ignoredTables)
        (D.defaultField "ignoredColumns" (Decode.list decodeColumnName) default.ignoredColumns)


encodeProjectId : ProjectId -> Value
encodeProjectId value =
    Encode.string value


decodeProjectId : Decode.Decoder ProjectId
decodeProjectId =
    Decode.string


encodeProjectName : ProjectName -> Value
encodeProjectName value =
    Encode.string value


decodeProjectName : Decode.Decoder ProjectName
decodeProjectName =
    Decode.string


encodeProjectSourceId : ProjectSourceId -> Value
encodeProjectSourceId value =
    Encode.string value


decodeProjectSourceId : Decode.Decoder ProjectSourceId
decodeProjectSourceId =
    Decode.string


encodeProjectSourceName : ProjectSourceName -> Value
encodeProjectSourceName value =
    Encode.string value


decodeProjectSourceName : Decode.Decoder ProjectSourceName
decodeProjectSourceName =
    Decode.string


encodeTableId : TableId -> Value
encodeTableId value =
    Encode.string (tableIdAsString value)


decodeTableId : Decode.Decoder TableId
decodeTableId =
    Decode.string |> Decode.map stringAsTableId


encodeSchemaName : SchemaName -> Value
encodeSchemaName value =
    Encode.string value


decodeSchemaName : Decode.Decoder SchemaName
decodeSchemaName =
    Decode.string


encodeTableName : TableName -> Value
encodeTableName value =
    Encode.string value


decodeTableName : Decode.Decoder TableName
decodeTableName =
    Decode.string


encodeColumnName : ColumnName -> Value
encodeColumnName value =
    Encode.string value


decodeColumnName : Decode.Decoder ColumnName
decodeColumnName =
    Decode.string


encodeColumnType : ColumnType -> Value
encodeColumnType value =
    Encode.string value


decodeColumnType : Decode.Decoder ColumnType
decodeColumnType =
    Decode.string


encodeColumnValue : ColumnValue -> Value
encodeColumnValue value =
    Encode.string value


decodeColumnValue : Decode.Decoder ColumnValue
decodeColumnValue =
    Decode.string


encodePrimaryKeyName : PrimaryKeyName -> Value
encodePrimaryKeyName value =
    Encode.string value


decodePrimaryKeyName : Decode.Decoder PrimaryKeyName
decodePrimaryKeyName =
    Decode.string


encodeUniqueName : UniqueName -> Value
encodeUniqueName value =
    Encode.string value


decodeUniqueName : Decode.Decoder UniqueName
decodeUniqueName =
    Decode.string


encodeIndexName : IndexName -> Value
encodeIndexName value =
    Encode.string value


decodeIndexName : Decode.Decoder IndexName
decodeIndexName =
    Decode.string


encodeCheckName : CheckName -> Value
encodeCheckName value =
    Encode.string value


decodeCheckName : Decode.Decoder CheckName
decodeCheckName =
    Decode.string


encodeRelationName : RelationName -> Value
encodeRelationName value =
    Encode.string value


decodeRelationName : Decode.Decoder RelationName
decodeRelationName =
    Decode.string


encodeLayoutName : LayoutName -> Value
encodeLayoutName value =
    Encode.string value


decodeLayoutName : Decode.Decoder LayoutName
decodeLayoutName =
    Decode.string
