module Models.Project.RelationId exposing (RelationId, new)

import Models.Project.ColumnId as ColumnId exposing (ColumnId)
import Models.Project.ColumnRef exposing (ColumnRef)


type alias RelationId =
    ( ColumnId, ColumnId )


new : ColumnRef -> ColumnRef -> RelationId
new src ref =
    ( ColumnId.from src, ColumnId.from ref )
