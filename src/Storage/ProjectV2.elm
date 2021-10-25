module Storage.ProjectV2 exposing (decodeCanvasProps, decodeCheck, decodeColumn, decodeColumnName, decodeColumnRef, decodeComment, decodeIndex, decodeLayout, decodeLayoutName, decodeOrigin, decodePrimaryKey, decodeProject, decodeProjectId, decodeProjectName, decodeProjectSettings, decodeRelation, decodeSampleName, decodeSource, decodeSourceId, decodeSourceKind, decodeSourceName, decodeTable, decodeTableId, decodeTableProps, decodeUnique, encodeCanvasProps, encodeCheck, encodeColumn, encodeColumnName, encodeColumnRef, encodeComment, encodeIndex, encodeLayout, encodeOrigin, encodePrimaryKey, encodeProject, encodeProjectId, encodeProjectName, encodeProjectSettings, encodeRelation, encodeSource, encodeSourceId, encodeSourceKind, encodeSourceName, encodeTable, encodeTableId, encodeTableProps, encodeUnique)

import Dict
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Dict as D
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Json.Formats exposing (decodeColor, decodeFileLineIndex, decodeFileModified, decodeFileName, decodeFileSize, decodeFileUrl, decodePosition, decodePosix, decodeZoomLevel, encodeColor, encodeFileLineIndex, encodeFileModified, encodeFileName, encodeFileSize, encodeFileUrl, encodePosition, encodePosix, encodeZoomLevel)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Models.Project as Project exposing (CanvasProps, Check, CheckName, Column, ColumnName, ColumnRef, ColumnType, ColumnValue, Comment, FindPathSettings, Index, IndexName, Layout, LayoutName, Origin, PrimaryKey, PrimaryKeyName, Project, ProjectId, ProjectName, ProjectSettings, Relation, RelationName, SampleName, Source, SourceId, SourceKind(..), SourceLine, SourceName, Table, TableProps, Unique, UniqueName, defaultLayout, defaultTime, initProjectSettings, layoutNameAsString, stringAsLayoutName)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)


currentVersion : Int
currentVersion =
    -- compatibility version for Project JSON, when you have breaking change, increment it and handle needed migrations
    2


encodeProject : Project -> Value
encodeProject value =
    E.object
        [ ( "id", value.id |> encodeProjectId )
        , ( "name", value.name |> encodeProjectName )
        , ( "sources", value.sources |> Encode.list encodeSource )
        , ( "layout", value.layout |> encodeLayout )
        , ( "usedLayout", value.usedLayout |> E.maybe encodeLayoutName )
        , ( "layouts", value.layouts |> Encode.dict layoutNameAsString encodeLayout )
        , ( "settings", value.settings |> E.withDefaultDeep encodeProjectSettings initProjectSettings )
        , ( "createdAt", value.createdAt |> encodePosix )
        , ( "updatedAt", value.updatedAt |> encodePosix )
        , ( "version", currentVersion |> Encode.int )
        ]


decodeProject : Decode.Decoder Project
decodeProject =
    D.map9 Project.build
        (Decode.field "id" decodeProjectId)
        (Decode.field "name" decodeProjectName)
        (Decode.field "sources" (Decode.list decodeSource))
        (D.defaultField "layout" decodeLayout defaultLayout)
        (D.maybeField "usedLayout" decodeLayoutName)
        (D.defaultField "layouts" (D.dict stringAsLayoutName decodeLayout) Dict.empty)
        (D.defaultFieldDeep "settings" decodeProjectSettings initProjectSettings)
        (D.defaultField "createdAt" decodePosix defaultTime)
        (D.defaultField "updatedAt" decodePosix defaultTime)


encodeSource : Source -> Value
encodeSource value =
    E.object
        [ ( "id", value.id |> encodeSourceId )
        , ( "name", value.name |> encodeSourceName )
        , ( "kind", value.kind |> encodeSourceKind )
        , ( "content", value.content |> Encode.array encodeSourceLine )
        , ( "tables", value.tables |> Dict.values |> Encode.list encodeTable )
        , ( "relations", value.relations |> Encode.list encodeRelation )
        , ( "enabled", value.enabled |> E.withDefault Encode.bool True )
        , ( "fromSample", value.fromSample |> E.maybe encodeSampleName )
        , ( "createdAt", value.createdAt |> encodePosix )
        , ( "updatedAt", value.updatedAt |> encodePosix )
        ]


decodeSource : Decode.Decoder Source
decodeSource =
    D.map10 Source
        (Decode.field "id" decodeSourceId)
        (Decode.field "name" decodeSourceName)
        (Decode.field "kind" decodeSourceKind)
        (Decode.field "content" (Decode.array decodeSourceLine))
        (Decode.field "tables" (Decode.list decodeTable) |> Decode.map (D.fromListMap .id))
        (Decode.field "relations" (Decode.list decodeRelation))
        (D.defaultField "enabled" Decode.bool True)
        (D.maybeField "fromSample" decodeSampleName)
        (Decode.field "createdAt" decodePosix)
        (Decode.field "updatedAt" decodePosix)


encodeSourceKind : SourceKind -> Value
encodeSourceKind value =
    case value of
        LocalFile name size modified ->
            E.object
                [ ( "kind", "LocalFile" |> Encode.string )
                , ( "name", name |> encodeFileName )
                , ( "size", size |> encodeFileSize )
                , ( "modified", modified |> encodeFileModified )
                ]

        RemoteFile name size ->
            E.object
                [ ( "kind", "RemoteFile" |> Encode.string )
                , ( "url", name |> encodeFileUrl )
                , ( "size", size |> encodeFileSize )
                ]


decodeSourceKind : Decode.Decoder SourceKind
decodeSourceKind =
    D.matchOn "kind"
        (\kind ->
            case kind of
                "LocalFile" ->
                    Decode.map3 LocalFile
                        (Decode.field "name" decodeFileName)
                        (Decode.field "size" decodeFileSize)
                        (Decode.field "modified" decodeFileModified)

                "RemoteFile" ->
                    Decode.map2 RemoteFile
                        (Decode.field "url" decodeFileUrl)
                        (Decode.field "size" decodeFileSize)

                other ->
                    Decode.fail ("Not supported kind of SourceKind '" ++ other ++ "'")
        )


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
        , ( "origins", value.origins |> E.withDefault (Encode.list encodeOrigin) [] )
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
        (D.defaultField "origins" (Decode.list decodeOrigin) [])


encodeColumn : Column -> Value
encodeColumn value =
    E.object
        [ ( "name", value.name |> encodeColumnName )
        , ( "type", value.kind |> encodeColumnType )
        , ( "nullable", value.nullable |> E.withDefault Encode.bool False )
        , ( "default", value.default |> E.maybe encodeColumnValue )
        , ( "comment", value.comment |> E.maybe encodeComment )
        , ( "origins", value.origins |> E.withDefault (Encode.list encodeOrigin) [] )
        ]


decodeColumn : Decode.Decoder (Int -> Column)
decodeColumn =
    Decode.map6 (\n t nu d c s -> \i -> Column i n t nu d c s)
        (Decode.field "name" decodeColumnName)
        (Decode.field "type" decodeColumnType)
        (D.defaultField "nullable" Decode.bool False)
        (D.maybeField "default" decodeColumnValue)
        (D.maybeField "comment" decodeComment)
        (D.defaultField "origins" (Decode.list decodeOrigin) [])


encodePrimaryKey : PrimaryKey -> Value
encodePrimaryKey value =
    E.object
        [ ( "name", value.name |> encodePrimaryKeyName )
        , ( "columns", value.columns |> E.nel encodeColumnName )
        , ( "origins", value.origins |> E.withDefault (Encode.list encodeOrigin) [] )
        ]


decodePrimaryKey : Decode.Decoder PrimaryKey
decodePrimaryKey =
    Decode.map3 PrimaryKey
        (Decode.field "name" decodePrimaryKeyName)
        (Decode.field "columns" (D.nel decodeColumnName))
        (D.defaultField "origins" (Decode.list decodeOrigin) [])


encodeUnique : Unique -> Value
encodeUnique value =
    E.object
        [ ( "name", value.name |> encodeUniqueName )
        , ( "columns", value.columns |> E.nel encodeColumnName )
        , ( "definition", value.definition |> Encode.string )
        , ( "origins", value.origins |> E.withDefault (Encode.list encodeOrigin) [] )
        ]


decodeUnique : Decode.Decoder Unique
decodeUnique =
    Decode.map4 Unique
        (Decode.field "name" decodeUniqueName)
        (Decode.field "columns" (D.nel decodeColumnName))
        (Decode.field "definition" Decode.string)
        (D.defaultField "origins" (Decode.list decodeOrigin) [])


encodeIndex : Index -> Value
encodeIndex value =
    E.object
        [ ( "name", value.name |> encodeIndexName )
        , ( "columns", value.columns |> E.nel encodeColumnName )
        , ( "definition", value.definition |> Encode.string )
        , ( "origins", value.origins |> E.withDefault (Encode.list encodeOrigin) [] )
        ]


decodeIndex : Decode.Decoder Index
decodeIndex =
    Decode.map4 Index
        (Decode.field "name" decodeIndexName)
        (Decode.field "columns" (D.nel decodeColumnName))
        (Decode.field "definition" Decode.string)
        (D.defaultField "origins" (Decode.list decodeOrigin) [])


encodeCheck : Check -> Value
encodeCheck value =
    E.object
        [ ( "name", value.name |> encodeCheckName )
        , ( "columns", value.columns |> E.withDefault (Encode.list encodeColumnName) [] )
        , ( "predicate", value.predicate |> Encode.string )
        , ( "origins", value.origins |> E.withDefault (Encode.list encodeOrigin) [] )
        ]


decodeCheck : Decode.Decoder Check
decodeCheck =
    Decode.map4 Check
        (Decode.field "name" decodeCheckName)
        (D.defaultField "columns" (Decode.list decodeColumnName) [])
        (Decode.field "predicate" Decode.string)
        (D.defaultField "origins" (Decode.list decodeOrigin) [])


encodeComment : Comment -> Value
encodeComment value =
    E.object
        [ ( "text", value.text |> Encode.string )
        , ( "origins", value.origins |> E.withDefault (Encode.list encodeOrigin) [] )
        ]


decodeComment : Decode.Decoder Comment
decodeComment =
    Decode.map2 Comment
        (Decode.field "text" Decode.string)
        (D.defaultField "origins" (Decode.list decodeOrigin) [])


encodeRelation : Relation -> Value
encodeRelation value =
    E.object
        [ ( "name", value.name |> encodeRelationName )
        , ( "src", value.src |> encodeColumnRef )
        , ( "ref", value.ref |> encodeColumnRef )
        , ( "origins", value.origins |> E.withDefault (Encode.list encodeOrigin) [] )
        ]


decodeRelation : Decode.Decoder Relation
decodeRelation =
    Decode.map4 Relation
        (Decode.field "name" decodeRelationName)
        (Decode.field "src" decodeColumnRef)
        (Decode.field "ref" decodeColumnRef)
        (D.defaultField "origins" (Decode.list decodeOrigin) [])


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


encodeOrigin : Origin -> Value
encodeOrigin value =
    E.object
        [ ( "id", value.id |> encodeSourceId )
        , ( "lines", value.lines |> Encode.list encodeFileLineIndex )
        ]


decodeOrigin : Decode.Decoder Origin
decodeOrigin =
    Decode.map2 Origin
        (Decode.field "id" decodeSourceId)
        (Decode.field "lines" (Decode.list decodeFileLineIndex))


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


encodeSourceId : SourceId -> Value
encodeSourceId value =
    Encode.string value


decodeSourceId : Decode.Decoder SourceId
decodeSourceId =
    Decode.string


encodeSourceName : SourceName -> Value
encodeSourceName value =
    Encode.string value


decodeSourceName : Decode.Decoder SourceName
decodeSourceName =
    Decode.string


encodeSourceLine : SourceLine -> Value
encodeSourceLine value =
    Encode.string value


decodeSourceLine : Decode.Decoder SourceLine
decodeSourceLine =
    Decode.string


encodeTableId : TableId -> Value
encodeTableId value =
    Encode.string (TableId.asString value)


decodeTableId : Decode.Decoder TableId
decodeTableId =
    Decode.string |> Decode.map TableId.parseString


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


encodeSampleName : SampleName -> Value
encodeSampleName value =
    Encode.string value


decodeSampleName : Decode.Decoder SampleName
decodeSampleName =
    Decode.string
