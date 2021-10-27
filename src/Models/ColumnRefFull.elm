module Models.ColumnRefFull exposing (ColumnRefFull)

import Libs.Size exposing (Size)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Table exposing (Table)
import Models.Project.TableProps exposing (TableProps)


type alias ColumnRefFull =
    { ref : ColumnRef, table : Table, column : Column, props : Maybe ( TableProps, Int, Size ) }
