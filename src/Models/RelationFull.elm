module Models.RelationFull exposing (RelationFull, hasRef, hasSrc, hasTableLink)

import Models.ColumnRefFull exposing (ColumnRefFull)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Origin exposing (Origin)
import Models.Project.RelationName exposing (RelationName)
import Models.Project.TableId exposing (TableId)


type alias RelationFull =
    { name : RelationName, src : ColumnRefFull, ref : ColumnRefFull, origins : List Origin }


hasTableLink : TableId -> RelationFull -> Bool
hasTableLink table relation =
    (relation.src.table.id == table) || (relation.ref.table.id == table)


hasSrc : TableId -> ColumnName -> RelationFull -> Bool
hasSrc table column relation =
    relation.src.table.id == table && relation.src.column.name == column


hasRef : TableId -> ColumnName -> RelationFull -> Bool
hasRef table column relation =
    relation.ref.table.id == table && relation.ref.column.name == column
