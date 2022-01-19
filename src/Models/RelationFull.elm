module Models.RelationFull exposing (RelationFull)

import Models.ColumnRefFull exposing (ColumnRefFull)
import Models.Project.Origin exposing (Origin)
import Models.Project.RelationName exposing (RelationName)


type alias RelationFull =
    { name : RelationName, src : ColumnRefFull, ref : ColumnRefFull, origins : List Origin }
