module PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn, create, unpack)

import Dict exposing (Dict)
import Libs.Maybe as Maybe
import Libs.Nel as Nel
import Models.Project.CheckName exposing (CheckName)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnIndex exposing (ColumnIndex)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.ColumnValue exposing (ColumnValue)
import Models.Project.Comment exposing (Comment)
import Models.Project.IndexName exposing (IndexName)
import Models.Project.Origin exposing (Origin)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.UniqueName exposing (UniqueName)
import PagesComponents.Projects.Id_.Models.ErdColumnRef as ErdColumnRef exposing (ErdColumnRef)


type alias ErdColumn =
    { index : ColumnIndex
    , name : ColumnName
    , kind : ColumnType
    , nullable : Bool
    , default : Maybe ColumnValue
    , comment : Maybe Comment
    , isPrimaryKey : Bool
    , inRelations : List ErdColumnRef
    , outRelations : List ErdColumnRef
    , uniques : List UniqueName
    , indexes : List IndexName
    , checks : List CheckName
    , origins : List Origin
    }


create : Dict TableId Table -> List Relation -> Table -> Column -> ErdColumn
create tables columnRelations table column =
    { index = column.index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment
    , isPrimaryKey = column.name |> Table.inPrimaryKey table |> Maybe.isJust
    , inRelations = columnRelations |> List.filter (\r -> r.ref.table == table.id && r.ref.column == column.name) |> List.map .src |> List.map (ErdColumnRef.create tables)
    , outRelations = columnRelations |> List.filter (\r -> r.src.table == table.id && r.src.column == column.name) |> List.map .ref |> List.map (ErdColumnRef.create tables)
    , uniques = table.uniques |> List.filter (.columns >> Nel.member column.name) |> List.map .name
    , indexes = table.indexes |> List.filter (.columns >> Nel.member column.name) |> List.map .name
    , checks = table.checks |> List.filter (.columns >> List.member column.name) |> List.map .name
    , origins = table.origins
    }


unpack : ErdColumn -> Column
unpack column =
    { index = column.index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment
    , origins = column.origins
    }
