module Models.Project.Relation exposing (Relation, build)

import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Origin exposing (Origin)
import Models.Project.RelationId as RelationId exposing (RelationId)
import Models.Project.RelationName exposing (RelationName)


type alias Relation =
    { id : RelationId, name : RelationName, src : ColumnRef, ref : ColumnRef, origins : List Origin }


build : RelationName -> ColumnRef -> ColumnRef -> List Origin -> Relation
build name src ref origins =
    Relation (RelationId.build src ref) name src ref origins
