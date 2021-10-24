module TestHelpers.ProjectFuzzers exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Fuzz exposing (Fuzzer)
import Libs.Dict as D
import Libs.Fuzz as F exposing (listN)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Models.Project exposing (CanvasProps, Check, CheckName, Column, ColumnIndex, ColumnName, ColumnRef, ColumnType, ColumnValue, Comment, FindPathSettings, Index, IndexName, Layout, LayoutName, Origin, PrimaryKey, PrimaryKeyName, Project, ProjectId, ProjectName, ProjectSettings, Relation, RelationName, SampleName, SchemaName, Source, SourceId, SourceKind(..), SourceLine, SourceName, Table, TableId, TableName, TableProps, Unique, UniqueName, buildProject)
import TestHelpers.Fuzzers exposing (color, dictSmall, fileLineIndex, fileModified, fileName, fileSize, fileUrl, identifier, intPosSmall, listSmall, nelSmall, position, posix, stringSmall, text, zoomLevel)


project : Fuzzer Project
project =
    F.map9 buildProject projectId projectName (listSmall source) layout (Fuzz.maybe layoutName) (dictSmall layoutName layout) projectSettings posix posix


source : Fuzzer Source
source =
    F.map10 Source sourceId sourceName sourceKind sourceLines tables (listSmall relation) Fuzz.bool sampleName posix posix


sourceKind : Fuzzer SourceKind
sourceKind =
    Fuzz.oneOf [ Fuzz.map3 LocalFile fileName fileSize fileModified, Fuzz.map2 RemoteFile fileUrl fileSize ]


sourceLines : Fuzzer (Array SourceLine)
sourceLines =
    listSmall stringSmall |> Fuzz.map Array.fromList


tables : Fuzzer (Dict TableId Table)
tables =
    listSmall table |> Fuzz.map (D.fromListMap .id)


table : Fuzzer Table
table =
    F.map9 (\s t c p u i ch co so -> Table ( s, t ) s t c p u i ch co so)
        schemaName
        tableName
        (nelSmall (column 0) |> Fuzz.map (Nel.uniqueBy .name >> Nel.indexedMap (\i c -> { c | index = i }) >> Ned.fromNelMap .name))
        (Fuzz.maybe primaryKey)
        (listSmall unique)
        (listSmall index)
        (listSmall check)
        (Fuzz.maybe comment)
        (listN 1 origin)


column : ColumnIndex -> Fuzzer Column
column i =
    F.map6 (Column i) columnName columnType Fuzz.bool (Fuzz.maybe columnValue) (Fuzz.maybe comment) (listN 1 origin)


primaryKey : Fuzzer PrimaryKey
primaryKey =
    Fuzz.map3 PrimaryKey primaryKeyName (nelSmall columnName) (listN 1 origin)


unique : Fuzzer Unique
unique =
    Fuzz.map4 Unique uniqueName (nelSmall columnName) text (listN 1 origin)


index : Fuzzer Index
index =
    Fuzz.map4 Index indexName (nelSmall columnName) text (listN 1 origin)


check : Fuzzer Check
check =
    Fuzz.map4 Check checkName (listSmall columnName) text (listN 1 origin)


comment : Fuzzer Comment
comment =
    Fuzz.map2 Comment text (listN 1 origin)


relation : Fuzzer Relation
relation =
    Fuzz.map4 Relation relationName columnRef columnRef (listN 1 origin)


columnRef : Fuzzer ColumnRef
columnRef =
    Fuzz.map2 ColumnRef tableId columnName


origin : Fuzzer Origin
origin =
    Fuzz.map2 Origin sourceId (listSmall fileLineIndex)


layout : Fuzzer Layout
layout =
    Fuzz.map5 Layout canvasProps (listSmall tableProps) (listSmall tableProps) posix posix


canvasProps : Fuzzer CanvasProps
canvasProps =
    Fuzz.map2 CanvasProps position zoomLevel


tableProps : Fuzzer TableProps
tableProps =
    Fuzz.map5 TableProps tableId position color (listSmall columnName) Fuzz.bool


projectSettings : Fuzzer ProjectSettings
projectSettings =
    Fuzz.map ProjectSettings findPathSettings


findPathSettings : Fuzzer FindPathSettings
findPathSettings =
    Fuzz.map3 FindPathSettings intPosSmall (listSmall tableId) (listSmall columnName)


projectId : Fuzzer ProjectId
projectId =
    identifier


projectName : Fuzzer ProjectName
projectName =
    identifier


sourceId : Fuzzer SourceId
sourceId =
    identifier


sourceName : Fuzzer SourceName
sourceName =
    identifier


tableId : Fuzzer TableId
tableId =
    Fuzz.tuple ( schemaName, tableName )


schemaName : Fuzzer SchemaName
schemaName =
    identifier


tableName : Fuzzer TableName
tableName =
    identifier


columnName : Fuzzer ColumnName
columnName =
    identifier


columnType : Fuzzer ColumnType
columnType =
    Fuzz.oneOf ([ "int", "serial", "varchar", "timestamp", "bigint", "text", "boolean", "character varying(10)" ] |> List.map Fuzz.constant)


columnValue : Fuzzer ColumnValue
columnValue =
    Fuzz.oneOf ([ "1", "false", "''::public.hstore", "default value: 'fr'::character varying" ] |> List.map Fuzz.constant)


primaryKeyName : Fuzzer PrimaryKeyName
primaryKeyName =
    identifier


uniqueName : Fuzzer UniqueName
uniqueName =
    identifier


indexName : Fuzzer IndexName
indexName =
    identifier


checkName : Fuzzer CheckName
checkName =
    identifier


relationName : Fuzzer RelationName
relationName =
    identifier


layoutName : Fuzzer LayoutName
layoutName =
    identifier


sampleName : Fuzzer (Maybe SampleName)
sampleName =
    Fuzz.oneOf [ Fuzz.constant (Just "basic"), Fuzz.constant Nothing ]
