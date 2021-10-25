module Models.Project.ColumnRef exposing (ColumnRef, show)

import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.TableId as TableId exposing (TableId)


type alias ColumnRef =
    { table : TableId, column : ColumnName }


show : ColumnRef -> String
show ref =
    TableId.show ref.table ++ "." ++ ref.column
