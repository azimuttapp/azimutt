module Models.Project.Column exposing (Column)

import Models.Project.ColumnIndex exposing (ColumnIndex)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.ColumnValue exposing (ColumnValue)
import Models.Project.Comment exposing (Comment)
import Models.Project.Origin exposing (Origin)


type alias Column =
    { index : ColumnIndex
    , name : ColumnName
    , kind : ColumnType
    , nullable : Bool
    , default : Maybe ColumnValue
    , comment : Maybe Comment
    , origins : List Origin
    }
