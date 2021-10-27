module Models.Project.Relation exposing (Relation, new, virtual)

import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Origin exposing (Origin)
import Models.Project.RelationId as RelationId exposing (RelationId)
import Models.Project.RelationName exposing (RelationName)
import Models.Project.SourceId exposing (SourceId)


type alias Relation =
    { id : RelationId, name : RelationName, src : ColumnRef, ref : ColumnRef, origins : List Origin }


new : RelationName -> ColumnRef -> ColumnRef -> List Origin -> Relation
new name src ref origins =
    Relation (RelationId.new src ref) name src ref origins


virtual : ColumnRef -> ColumnRef -> SourceId -> Relation
virtual src ref source =
    new "virtual relation" src ref [ Origin source [] ]
