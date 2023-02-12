module Models.Project.ColumnId exposing (ColumnId, from, fromRef, show)

import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.ColumnRef exposing (ColumnRefLike)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId exposing (TableId)


type alias ColumnId =
    -- Like ColumnRef but comparable (tuple instead of record)
    ( TableId, ColumnPathStr )


show : SchemaName -> ColumnId -> String
show defaultSchema ( table, column ) =
    TableId.show defaultSchema table |> ColumnPath.withName (ColumnPath.fromString column)


from : { t | id : TableId } -> { c | path : ColumnPath } -> ColumnId
from table column =
    ( table.id, ColumnPath.toString column.path )


fromRef : ColumnRefLike x -> ColumnId
fromRef ref =
    ( ref.table, ColumnPath.toString ref.column )
