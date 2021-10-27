module Models.Project.Unique exposing (Unique)

import Libs.Nel exposing (Nel)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Origin exposing (Origin)
import Models.Project.UniqueName exposing (UniqueName)


type alias Unique =
    { name : UniqueName, columns : Nel ColumnName, definition : String, origins : List Origin }
