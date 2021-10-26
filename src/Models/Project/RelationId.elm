module Models.Project.RelationId exposing (RelationId, build)

import Models.Project.ColumnId as ColumnId exposing (ColumnId)
import Models.Project.ColumnRef exposing (ColumnRef)


type alias RelationId =
    ( ColumnId, ColumnId )


build : ColumnRef -> ColumnRef -> RelationId
build src ref =
    ( ColumnId.from src, ColumnId.from ref )
