module TestHelpers.ProjectFuzzers exposing (..)

import Fuzz exposing (Fuzzer)
import Libs.Fuzz as F exposing (listN, nelN)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Models.Project exposing (CanvasProps, Check, CheckName, Column, ColumnIndex, ColumnName, ColumnRef, ColumnType, ColumnValue, Comment, FindPathSettings, Index, IndexName, Layout, LayoutName, PrimaryKey, PrimaryKeyName, Project, ProjectId, ProjectName, ProjectSettings, ProjectSource, ProjectSourceContent(..), ProjectSourceId, ProjectSourceName, Relation, RelationName, Schema, SchemaName, Source, SourceLine, Table, TableId, TableName, TableProps, Unique, UniqueName)
import TestHelpers.Fuzzers exposing (color, dictSmall, identifier, intPos, intPosSmall, listSmall, nelSmall, position, posix, text, zoomLevel)


project : Fuzzer Project
project =
    F.map9 Project projectId projectName (nelSmall projectSource) schema (dictSmall layoutName layout) (Fuzz.maybe layoutName) projectSettings posix posix


projectSource : Fuzzer ProjectSource
projectSource =
    Fuzz.map5 ProjectSource projectSourceId projectSourceName projectSourceContent posix posix


projectSourceContent : Fuzzer ProjectSourceContent
projectSourceContent =
    Fuzz.oneOf [ Fuzz.map3 LocalFile identifier intPos posix ]


schema : Fuzzer Schema
schema =
    Fuzz.map3 Schema (dictSmall tableId table) (listSmall relation) layout


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
        (listN 1 source)


column : ColumnIndex -> Fuzzer Column
column i =
    F.map6 (Column i) columnName columnType Fuzz.bool (Fuzz.maybe columnValue) (Fuzz.maybe comment) (listN 1 source)


primaryKey : Fuzzer PrimaryKey
primaryKey =
    Fuzz.map3 PrimaryKey primaryKeyName (nelSmall columnName) (listN 1 source)


unique : Fuzzer Unique
unique =
    Fuzz.map4 Unique uniqueName (nelSmall columnName) text (listN 1 source)


index : Fuzzer Index
index =
    Fuzz.map4 Index indexName (nelSmall columnName) text (listN 1 source)


check : Fuzzer Check
check =
    Fuzz.map3 Check checkName text (listN 1 source)


comment : Fuzzer Comment
comment =
    Fuzz.map2 Comment text (listN 1 source)


relation : Fuzzer Relation
relation =
    Fuzz.map4 Relation relationName columnRef columnRef (listN 1 source)


columnRef : Fuzzer ColumnRef
columnRef =
    Fuzz.map2 ColumnRef tableId columnName


source : Fuzzer Source
source =
    Fuzz.map2 Source projectSourceId (nelN 1 sourceLine)


sourceLine : Fuzzer SourceLine
sourceLine =
    Fuzz.map2 SourceLine intPos text


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


projectSourceId : Fuzzer ProjectSourceId
projectSourceId =
    identifier


projectSourceName : Fuzzer ProjectSourceName
projectSourceName =
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


columnIndex : Fuzzer ColumnIndex
columnIndex =
    Fuzz.intRange 0 100


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
