module Models.Project.ColumnId exposing (ColumnId, from, show)

import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRefLike)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId exposing (TableId)


type alias ColumnId =
    ( TableId, ColumnName )


show : SchemaName -> ColumnId -> String
show defaultSchema ( table, column ) =
    TableId.show defaultSchema table |> ColumnName.withName column


from : ColumnRefLike x -> ColumnId
from ref =
    ( ref.table, ref.column )
