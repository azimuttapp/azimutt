module Models.Project.Table exposing (Table)

import Libs.Ned exposing (Ned)
import Models.Project.Check exposing (Check)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Comment exposing (Comment)
import Models.Project.Index exposing (Index)
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import Models.Project.Unique exposing (Unique)


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
    , origins : List Origin
    }
