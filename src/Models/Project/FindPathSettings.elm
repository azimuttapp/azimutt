module Models.Project.FindPathSettings exposing (FindPathSettings)

import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.TableId exposing (TableId)


type alias FindPathSettings =
    { maxPathLength : Int, ignoredTables : List TableId, ignoredColumns : List ColumnName }
