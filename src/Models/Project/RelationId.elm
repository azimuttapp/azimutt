module Models.Project.RelationId exposing (RelationId, new, show)

import Models.Project.ColumnId as ColumnId exposing (ColumnId)
import Models.Project.ColumnRef exposing (ColumnRefLike)
import Models.Project.SchemaName exposing (SchemaName)


type alias RelationId =
    ( ColumnId, ColumnId )


new : ColumnRefLike x -> ColumnRefLike x -> RelationId
new src ref =
    ( ColumnId.from src, ColumnId.from ref )


show : SchemaName -> RelationId -> String
show defaultSchema ( src, ref ) =
    ColumnId.show defaultSchema src ++ " -> " ++ ColumnId.show defaultSchema ref
