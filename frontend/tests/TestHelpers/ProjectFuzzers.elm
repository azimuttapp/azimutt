module TestHelpers.ProjectFuzzers exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Fuzz exposing (Fuzzer)
import Libs.Dict as Dict
import Libs.Fuzz as Fuzz
import Libs.List as List
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.Project exposing (Project)
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.Check exposing (Check)
import Models.Project.CheckName exposing (CheckName)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnIndex exposing (ColumnIndex)
import Models.Project.ColumnMeta exposing (ColumnMeta)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.ColumnValue exposing (ColumnValue)
import Models.Project.Comment exposing (Comment)
import Models.Project.CustomType as CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.CustomTypeName exposing (CustomTypeName)
import Models.Project.CustomTypeValue as CustomTypeValue exposing (CustomTypeValue)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.Group exposing (Group)
import Models.Project.Index exposing (Index)
import Models.Project.IndexName exposing (IndexName)
import Models.Project.Layout exposing (Layout)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.PrimaryKeyName exposing (PrimaryKeyName)
import Models.Project.ProjectEncodingVersion as ProjectEncodingVersion exposing (ProjectEncodingVersion)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectSettings exposing (HiddenColumns, ProjectSettings)
import Models.Project.ProjectSlug exposing (ProjectSlug)
import Models.Project.ProjectStorage as ProjectStrorage exposing (ProjectStorage)
import Models.Project.ProjectVisibility as ProjectVisibility exposing (ProjectVisibility)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.RelationName exposing (RelationName)
import Models.Project.SampleKey exposing (SampleKey)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.SourceLine exposing (SourceLine)
import Models.Project.SourceName exposing (SourceName)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableMeta exposing (TableMeta)
import Models.Project.TableName exposing (TableName)
import Models.Project.TableProps exposing (TableProps)
import Models.Project.TableRow as TableRow exposing (TableRow)
import Models.Project.Unique exposing (Unique)
import Models.Project.UniqueName exposing (UniqueName)
import Models.RelationStyle as RelationStyle exposing (RelationStyle)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId exposing (MemoId)
import Services.QueryBuilder as QueryBuilder
import TestHelpers.Fuzzers exposing (color, dbValue, dictSmall, fileLineIndex, fileModified, fileName, fileSize, fileUrl, identifier, intPosSmall, listSmall, nelSmall, positionDiagram, positionGrid, posix, setSmall, sizeCanvas, stringSmall, text, uuid, zoomLevel)
import TestHelpers.OrganizationFuzzers exposing (organization)


project : Fuzzer Project
project =
    Fuzz.map15 Project (Fuzz.maybe organization) projectId projectSlug projectName (Fuzz.maybe stringSmall) (listSmall source) (dictSmall tableId tableMeta) (dictSmall layoutName layout) intPosSmall projectSettings projectStorage projectVisibility projectEncodingVersion posix posix


source : Fuzzer Source
source =
    Fuzz.map11 Source sourceId sourceName sourceKind sourceLines tables (listSmall relation) types Fuzz.bool (Fuzz.maybe sampleName) posix posix


sourceKind : Fuzzer SourceKind
sourceKind =
    Fuzz.oneOf [ Fuzz.map3 SqlLocalFile fileName fileSize fileModified, Fuzz.map2 SqlRemoteFile fileUrl fileSize, Fuzz.constant AmlEditor ]


sourceLines : Fuzzer (Array SourceLine)
sourceLines =
    listSmall stringSmall |> Fuzz.map Array.fromList


tables : Fuzzer (Dict TableId Table)
tables =
    listSmall table |> Fuzz.map (Dict.fromListMap .id)


table : Fuzzer Table
table =
    Fuzz.map10 Table.new
        schemaName
        tableName
        Fuzz.bool
        (listSmall (column 0) |> Fuzz.map (List.uniqueBy .name >> List.indexedMap (\i c -> { c | index = i }) >> Dict.fromListMap .name))
        (Fuzz.maybe primaryKey)
        (listSmall unique)
        (listSmall index)
        (listSmall check)
        (Fuzz.maybe comment)
        (Fuzz.listN 1 origin)


column : ColumnIndex -> Fuzzer Column
column i =
    Fuzz.map7 (Column i) columnName columnType Fuzz.bool (Fuzz.maybe columnValue) (Fuzz.maybe comment) (Fuzz.constant Nothing) (Fuzz.listN 1 origin)


primaryKey : Fuzzer PrimaryKey
primaryKey =
    Fuzz.map3 PrimaryKey (Fuzz.maybe primaryKeyName) (nelSmall columnPath) (Fuzz.listN 1 origin)


unique : Fuzzer Unique
unique =
    Fuzz.map4 Unique uniqueName (nelSmall columnPath) (Fuzz.maybe text) (Fuzz.listN 1 origin)


index : Fuzzer Index
index =
    Fuzz.map4 Index indexName (nelSmall columnPath) (Fuzz.maybe text) (Fuzz.listN 1 origin)


check : Fuzzer Check
check =
    Fuzz.map4 Check checkName (listSmall columnPath) (Fuzz.maybe text) (Fuzz.listN 1 origin)


comment : Fuzzer Comment
comment =
    Fuzz.map2 Comment text (Fuzz.listN 1 origin)


types : Fuzzer (Dict CustomTypeId CustomType)
types =
    listSmall customType |> Fuzz.map (Dict.fromListMap .id)


customType : Fuzzer CustomType
customType =
    Fuzz.map4 CustomType.new schemaName customTypeName customTypeValue (Fuzz.listN 1 origin)


customTypeValue : Fuzzer CustomTypeValue
customTypeValue =
    Fuzz.oneOf
        [ listSmall stringSmall |> Fuzz.map CustomTypeValue.Enum
        , stringSmall |> Fuzz.map CustomTypeValue.Definition
        ]


relation : Fuzzer Relation
relation =
    Fuzz.map4 Relation.new relationName columnRef columnRef (Fuzz.listN 1 origin)


columnRef : Fuzzer ColumnRef
columnRef =
    Fuzz.map2 ColumnRef tableId columnPath


origin : Fuzzer Origin
origin =
    Fuzz.map2 Origin sourceId (listSmall fileLineIndex)


tableMeta : Fuzzer TableMeta
tableMeta =
    Fuzz.map3 TableMeta (Fuzz.maybe stringSmall) (listSmall stringSmall) (dictSmall columnPathStr columnMeta)


columnMeta : Fuzzer ColumnMeta
columnMeta =
    Fuzz.map2 ColumnMeta (Fuzz.maybe stringSmall) (listSmall stringSmall)


layout : Fuzzer Layout
layout =
    Fuzz.map6 Layout (listSmall tableProps) (listSmall tableRow) (listSmall group) (listSmall memo) posix posix


canvasProps : Fuzzer CanvasProps
canvasProps =
    Fuzz.map2 CanvasProps positionDiagram zoomLevel


tableProps : Fuzzer TableProps
tableProps =
    Fuzz.map7 (\id p -> TableProps id p Size.zeroCanvas) tableId positionGrid color (listSmall columnPath) Fuzz.bool Fuzz.bool Fuzz.bool


group : Fuzzer Group
group =
    Fuzz.map4 Group stringSmall (listSmall tableId) color Fuzz.bool


memo : Fuzzer Memo
memo =
    Fuzz.map6 Memo memoId stringSmall positionGrid sizeCanvas (Fuzz.maybe color) Fuzz.bool


memoId : Fuzzer MemoId
memoId =
    intPosSmall


tableRow : Fuzzer TableRow
tableRow =
    Fuzz.map7 TableRow tableRowId positionGrid sizeCanvas sourceId rowQuery tableRowState Fuzz.bool


tableRowId : Fuzzer TableRow.Id
tableRowId =
    intPosSmall


tableRowState : Fuzzer TableRow.State
tableRowState =
    Fuzz.oneOf
        [ tableRowLoading |> Fuzz.map TableRow.StateLoading
        , tableRowFailure |> Fuzz.map TableRow.StateFailure
        , tableRowSuccess |> Fuzz.map TableRow.StateSuccess
        ]


tableRowLoading : Fuzzer TableRow.LoadingState
tableRowLoading =
    Fuzz.map3 TableRow.LoadingState stringSmall posix (Fuzz.maybe tableRowSuccess)


tableRowFailure : Fuzzer TableRow.FailureState
tableRowFailure =
    Fuzz.map5 TableRow.FailureState stringSmall stringSmall posix posix (Fuzz.maybe tableRowSuccess)


tableRowSuccess : Fuzzer TableRow.SuccessState
tableRowSuccess =
    Fuzz.map6 TableRow.SuccessState (listSmall tableRowValue) (setSmall columnName) (setSmall columnName) Fuzz.bool posix posix


tableRowValue : Fuzzer TableRow.TableRowValue
tableRowValue =
    Fuzz.map2 TableRow.TableRowValue columnName dbValue


rowQuery : Fuzzer QueryBuilder.RowQuery
rowQuery =
    Fuzz.map2 QueryBuilder.RowQuery tableId (nelSmall columnMatch)


columnMatch : Fuzzer QueryBuilder.ColumnMatch
columnMatch =
    Fuzz.map2 QueryBuilder.ColumnMatch columnPath dbValue


projectSettings : Fuzzer ProjectSettings
projectSettings =
    Fuzz.map10 ProjectSettings findPathSettings schemaName (listSmall schemaName) Fuzz.bool stringSmall findHiddenColumns columnOrder relationStyle Fuzz.bool Fuzz.bool


findPathSettings : Fuzzer FindPathSettings
findPathSettings =
    Fuzz.map3 FindPathSettings intPosSmall stringSmall stringSmall


findHiddenColumns : Fuzzer HiddenColumns
findHiddenColumns =
    Fuzz.map4 HiddenColumns stringSmall Fuzz.int Fuzz.bool Fuzz.bool


projectStorage : Fuzzer ProjectStorage
projectStorage =
    Fuzz.oneOf ([ ProjectStrorage.Local, ProjectStrorage.Remote ] |> List.map Fuzz.constant)


projectVisibility : Fuzzer ProjectVisibility
projectVisibility =
    Fuzz.oneOf ([ ProjectVisibility.None, ProjectVisibility.Read, ProjectVisibility.Write ] |> List.map Fuzz.constant)


projectEncodingVersion : Fuzzer ProjectEncodingVersion
projectEncodingVersion =
    Fuzz.constant ProjectEncodingVersion.current


projectId : Fuzzer ProjectId
projectId =
    uuid


projectSlug : Fuzzer ProjectSlug
projectSlug =
    identifier


projectName : Fuzzer ProjectName
projectName =
    identifier


sourceId : Fuzzer SourceId
sourceId =
    uuid |> Fuzz.map SourceId.new


sourceName : Fuzzer SourceName
sourceName =
    identifier


tableId : Fuzzer TableId
tableId =
    Fuzz.pair schemaName tableName


schemaName : Fuzzer SchemaName
schemaName =
    identifier


tableName : Fuzzer TableName
tableName =
    identifier


columnName : Fuzzer ColumnName
columnName =
    identifier


columnPath : Fuzzer ColumnPath
columnPath =
    identifier |> Fuzz.map ColumnPath.fromString


columnPathStr : Fuzzer ColumnPathStr
columnPathStr =
    columnPath |> Fuzz.map ColumnPath.toString


columnType : Fuzzer ColumnType
columnType =
    Fuzz.oneOf ([ "int", "serial", "varchar", "timestamp", "bigint", "text", "boolean", "character varying(10)" ] |> List.map Fuzz.constant)


columnValue : Fuzzer ColumnValue
columnValue =
    Fuzz.oneOf ([ "1", "false", "''::public.hstore", "default value: 'fr'::character varying" ] |> List.map Fuzz.constant)


columnOrder : Fuzzer ColumnOrder
columnOrder =
    Fuzz.oneOf (ColumnOrder.all |> List.map Fuzz.constant)


customTypeName : Fuzzer CustomTypeName
customTypeName =
    identifier


relationStyle : Fuzzer RelationStyle
relationStyle =
    Fuzz.oneOf (RelationStyle.all |> List.map Fuzz.constant)


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


sampleName : Fuzzer SampleKey
sampleName =
    Fuzz.oneOf ([ "basic", "gospeak", "postgres" ] |> List.map Fuzz.constant)
