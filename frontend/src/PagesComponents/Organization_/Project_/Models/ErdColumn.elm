module PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn, ErdNestedColumns(..), create, getColumn, unpack)

import Dict exposing (Dict)
import Libs.Maybe as Maybe
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel exposing (Nel)
import Models.Project.CheckName exposing (CheckName)
import Models.Project.Column exposing (Column, NestedColumns(..))
import Models.Project.ColumnIndex exposing (ColumnIndex)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType as ColumnType exposing (ColumnType)
import Models.Project.ColumnValue as ColumnValue exposing (ColumnValue)
import Models.Project.Comment exposing (Comment)
import Models.Project.CustomType as CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.IndexName exposing (IndexName)
import Models.Project.Origin exposing (Origin)
import Models.Project.Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.UniqueName exposing (UniqueName)
import PagesComponents.Organization_.Project_.Models.ErdColumnRef as ErdColumnRef exposing (ErdColumnRef)


type alias ErdColumn =
    { index : ColumnIndex
    , name : ColumnName
    , kind : ColumnType
    , kindLabel : String
    , customType : Maybe CustomType
    , nullable : Bool
    , default : Maybe ColumnValue
    , defaultLabel : Maybe String
    , comment : Maybe Comment
    , isPrimaryKey : Bool
    , inRelations : List ErdColumnRef
    , outRelations : List ErdColumnRef
    , uniques : List UniqueName
    , indexes : List IndexName
    , checks : List CheckName
    , columns : Maybe ErdNestedColumns
    , origins : List Origin
    }


type ErdNestedColumns
    = ErdNestedColumns (Ned ColumnName ErdColumn)


create : SchemaName -> Dict TableId Table -> Dict CustomTypeId CustomType -> List Relation -> Table -> Column -> ErdColumn
create defaultSchema tables types columnRelations table column =
    { index = column.index
    , name = column.name
    , kind = column.kind
    , kindLabel = column.kind |> ColumnType.label defaultSchema
    , customType = types |> CustomType.get defaultSchema column.kind
    , nullable = column.nullable
    , default = column.default
    , defaultLabel = column.default |> Maybe.map ColumnValue.label
    , comment = column.comment
    , isPrimaryKey = column.name |> Table.inPrimaryKey table |> Maybe.isJust
    , inRelations = columnRelations |> List.filter (\r -> r.ref.table == table.id && r.ref.column == column.name) |> List.map .src |> List.map (ErdColumnRef.create tables)
    , outRelations = columnRelations |> List.filter (\r -> r.src.table == table.id && r.src.column == column.name) |> List.map .ref |> List.map (ErdColumnRef.create tables)
    , uniques = table.uniques |> List.filter (.columns >> Nel.member column.name) |> List.map .name
    , indexes = table.indexes |> List.filter (.columns >> Nel.member column.name) |> List.map .name
    , checks = table.checks |> List.filter (.columns >> List.member column.name) |> List.map .name
    , columns = column.columns |> Maybe.map (\(NestedColumns cols) -> cols |> Ned.map (\_ -> createNested defaultSchema types) |> ErdNestedColumns)
    , origins = table.origins
    }


createNested : SchemaName -> Dict CustomTypeId CustomType -> Column -> ErdColumn
createNested defaultSchema types column =
    { index = column.index
    , name = column.name
    , kind = column.kind
    , kindLabel = column.kind |> ColumnType.label defaultSchema
    , customType = types |> CustomType.get defaultSchema column.kind
    , nullable = column.nullable
    , default = column.default
    , defaultLabel = column.default |> Maybe.map ColumnValue.label
    , comment = column.comment
    , isPrimaryKey = False
    , inRelations = []
    , outRelations = []
    , uniques = []
    , indexes = []
    , checks = []
    , columns = column.columns |> Maybe.map (\(NestedColumns cols) -> cols |> Ned.map (\_ -> createNested defaultSchema types) |> ErdNestedColumns)
    , origins = []
    }


unpack : ErdColumn -> Column
unpack column =
    { index = column.index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment
    , columns = column.columns |> Maybe.map (\(ErdNestedColumns cols) -> cols |> Ned.map (\_ -> unpack) |> NestedColumns)
    , origins = column.origins
    }


getColumn : ColumnPath -> ErdColumn -> Maybe ErdColumn
getColumn path column =
    column.columns
        |> Maybe.andThen (\(ErdNestedColumns cols) -> cols |> Ned.get path.head)
        |> Maybe.andThen (\col -> path.tail |> Nel.fromList |> Maybe.mapOrElse (\next -> getColumn next col) (Just col))
