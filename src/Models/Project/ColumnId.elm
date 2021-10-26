module Models.Project.ColumnId exposing (ColumnId, from)

import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.TableId exposing (TableId)


type alias ColumnId =
    ( TableId, ColumnName )


from : ColumnRef -> ColumnId
from ref =
    ( ref.table, ref.column )
