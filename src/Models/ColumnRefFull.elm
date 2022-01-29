module Models.ColumnRefFull exposing (ColumnRefFull, show)

import Libs.Models.Size exposing (Size)
import Models.Project.Column as Column exposing (Column)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId
import Models.Project.TableProps exposing (TableProps)


type alias ColumnRefFull =
    -- FIXME: use Maybe ( Int, TableProps ) in props (Size is now inside TableProps)
    { ref : ColumnRef, table : Table, column : Column, props : Maybe ( TableProps, Int, Size ) }


show : ColumnRefFull -> String
show { table, column } =
    TableId.show table.id |> Column.withName column
