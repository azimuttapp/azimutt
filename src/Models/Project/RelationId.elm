module Models.Project.RelationId exposing (RelationId, new, show)

import Models.Project.ColumnId as ColumnId exposing (ColumnId)
import Models.Project.ColumnRef exposing (ColumnRef)


type alias RelationId =
    ( ColumnId, ColumnId )


new : ColumnRef -> ColumnRef -> RelationId
new src ref =
    ( ColumnId.from src, ColumnId.from ref )


show : RelationId -> String
show ( src, ref ) =
    ColumnId.show src ++ " -> " ++ ColumnId.show ref
