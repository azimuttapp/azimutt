module Models.Project.PrimaryKey exposing (PrimaryKey)

import Libs.Nel exposing (Nel)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKeyName exposing (PrimaryKeyName)


type alias PrimaryKey =
    { name : PrimaryKeyName, columns : Nel ColumnName, origins : List Origin }
