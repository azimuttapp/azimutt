module Models.Project.Index exposing (Index)

import Libs.Nel exposing (Nel)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.IndexName exposing (IndexName)
import Models.Project.Origin exposing (Origin)


type alias Index =
    { name : IndexName, columns : Nel ColumnName, definition : String, origins : List Origin }
