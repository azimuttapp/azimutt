module TestHelpers.ProjectFuzzers exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Fuzz exposing (Fuzzer)
import Libs.Dict as Dict
import Libs.Fuzz as F exposing (listN)
import Libs.Models.Size as Size
import Libs.Ned as Ned
import Libs.Nel as Nel
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.Project as Project exposing (Project)
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.Check exposing (Check)
import Models.Project.CheckName exposing (CheckName)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnIndex exposing (ColumnIndex)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.ColumnValue exposing (ColumnValue)
import Models.Project.Comment exposing (Comment)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.Index exposing (Index)
import Models.Project.IndexName exposing (IndexName)
import Models.Project.Layout exposing (Layout)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.PrimaryKeyName exposing (PrimaryKeyName)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectSettings exposing (HiddenColumns, ProjectSettings)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.RelationName exposing (RelationName)
import Models.Project.SampleKey exposing (SampleKey)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.SourceLine exposing (SourceLine)
import Models.Project.SourceName exposing (SourceName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import Models.Project.TableProps exposing (TableProps)
import Models.Project.Unique exposing (Unique)
import Models.Project.UniqueName exposing (UniqueName)
import TestHelpers.Fuzzers exposing (color, dictSmall, fileLineIndex, fileModified, fileName, fileSize, fileUrl, identifier, intPosSmall, listSmall, nelSmall, position, posix, stringSmall, text, zoomLevel)


project : Fuzzer Project
project =
    F.map9 Project.new projectId projectName (listSmall source) layout (Fuzz.maybe layoutName) (dictSmall layoutName layout) projectSettings posix posix


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
    listSmall table |> Fuzz.map (Dict.fromListMap .id)


table : Fuzzer Table
table =
    F.map10 (\s t v c p u i ch co so -> Table ( s, t ) s t v c p u i ch co so)
        schemaName
        tableName
        Fuzz.bool
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
    Fuzz.map4 Relation.new relationName columnRef columnRef (listN 1 origin)


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
    F.map6 (\id p c cols s h -> TableProps id p Size.zero c cols s h) tableId position color (listSmall columnName) Fuzz.bool Fuzz.bool


projectSettings : Fuzzer ProjectSettings
projectSettings =
    F.map7 ProjectSettings findPathSettings (listSmall schemaName) Fuzz.bool stringSmall findHiddenColumns columnOrder Fuzz.bool


findPathSettings : Fuzzer FindPathSettings
findPathSettings =
    Fuzz.map3 FindPathSettings intPosSmall Fuzz.string Fuzz.string


findHiddenColumns : Fuzzer HiddenColumns
findHiddenColumns =
    Fuzz.map3 HiddenColumns stringSmall Fuzz.bool Fuzz.bool


projectId : Fuzzer ProjectId
projectId =
    identifier


projectName : Fuzzer ProjectName
projectName =
    identifier


sourceId : Fuzzer SourceId
sourceId =
    identifier |> Fuzz.map SourceId.new


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


columnOrder : Fuzzer ColumnOrder
columnOrder =
    Fuzz.oneOf (ColumnOrder.all |> List.map Fuzz.constant)


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


sampleName : Fuzzer (Maybe SampleKey)
sampleName =
    Fuzz.oneOf [ Fuzz.constant (Just "basic"), Fuzz.constant Nothing ]
