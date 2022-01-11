module Models.Project.ColumnId exposing (ColumnId, from, show)

import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.TableId as TableId exposing (TableId)


type alias ColumnId =
    ( TableId, ColumnName )


show : ColumnId -> String
show ( table, column ) =
    TableId.show table ++ "." ++ column


from : ColumnRef -> ColumnId
from ref =
    ( ref.table, ref.column )
