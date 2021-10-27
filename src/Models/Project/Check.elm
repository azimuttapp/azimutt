module Models.Project.Check exposing (Check)

import Models.Project.CheckName exposing (CheckName)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Origin exposing (Origin)


type alias Check =
    { name : CheckName, columns : List ColumnName, predicate : String, origins : List Origin }
