module PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn, ErdNestedColumns(..), create, getColumn, unpack, withNullable)

import Dict exposing (Dict)
import Libs.Maybe as Maybe
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel exposing (Nel)
import Models.Project.CheckName exposing (CheckName)
import Models.Project.Column exposing (Column, NestedColumns(..))
import Models.Project.ColumnIndex exposing (ColumnIndex)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType as ColumnType exposing (ColumnType)
import Models.Project.ColumnValue as ColumnValue exposing (ColumnValue)
import Models.Project.Comment exposing (Comment)
import Models.Project.CustomType as CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.IndexName exposing (IndexName)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.Table exposing (Table)
import Models.Project.UniqueName exposing (UniqueName)
import PagesComponents.Organization_.Project_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Organization_.Project_.Models.ErdOrigin as ErdOrigin exposing (ErdOrigin)
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)


type alias ErdColumn =
    { index : ColumnIndex
    , path : ColumnPath
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
    , values : Maybe (Nel String)
    , columns : Maybe ErdNestedColumns
    , origins : List ErdOrigin
    }


type ErdNestedColumns
    = ErdNestedColumns (Ned ColumnName ErdColumn)


create : SchemaName -> List Source -> Dict CustomTypeId CustomType -> List ErdRelation -> Table -> ColumnPath -> Column -> ErdColumn
create defaultSchema sources types columnRelations table path column =
    { index = column.index
    , path = path
    , kind = column.kind
    , kindLabel = column.kind |> ColumnType.label defaultSchema
    , customType = types |> CustomType.get defaultSchema column.kind
    , nullable = column.nullable
    , default = column.default
    , defaultLabel = column.default |> Maybe.map ColumnValue.label
    , comment = column.comment
    , isPrimaryKey = table.primaryKey |> Maybe.filter (.columns >> Nel.member path) |> Maybe.isJust
    , inRelations = columnRelations |> List.filter (\r -> r.ref.table == table.id && r.ref.column == path) |> List.map .src
    , outRelations = columnRelations |> List.filter (\r -> r.src.table == table.id && r.src.column == path) |> List.map .ref
    , uniques = table.uniques |> List.filter (.columns >> Nel.member path) |> List.map .name
    , indexes = table.indexes |> List.filter (.columns >> Nel.member path) |> List.map .name
    , checks = table.checks |> List.filter (.columns >> List.member path) |> List.map .name
    , values = column.values
    , columns = column.columns |> Maybe.map (\(NestedColumns cols) -> cols |> Ned.map (\name -> create defaultSchema sources types columnRelations table (path |> ColumnPath.child name)) |> ErdNestedColumns)
    , origins = column.origins |> List.map (ErdOrigin.create sources)
    }


unpack : ErdColumn -> Column
unpack column =
    { index = column.index
    , name = column.path |> ColumnPath.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment
    , values = column.values
    , columns = column.columns |> Maybe.map (\(ErdNestedColumns cols) -> cols |> Ned.map (\_ -> unpack) |> NestedColumns)
    , origins = column.origins |> List.map ErdOrigin.unpack
    }


getColumn : ColumnPath -> ErdColumn -> Maybe ErdColumn
getColumn path column =
    column.columns
        |> Maybe.andThen (\(ErdNestedColumns cols) -> cols |> Ned.get path.head)
        |> Maybe.andThen (\col -> path.tail |> Nel.fromList |> Maybe.mapOrElse (\next -> getColumn next col) (Just col))


withNullable : ErdColumn -> String -> String
withNullable column text =
    if column.nullable then
        text ++ "?"

    else
        text
