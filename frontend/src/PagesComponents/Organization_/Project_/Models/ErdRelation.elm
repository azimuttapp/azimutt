module PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation, create, label, new, unpack)

import Dict exposing (Dict)
import Models.Project.ColumnRef as ColumnRef
import Models.Project.Origin exposing (Origin)
import Models.Project.Relation exposing (Relation)
import Models.Project.RelationId as RelationId exposing (RelationId)
import Models.Project.RelationName exposing (RelationName)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models.ErdColumnRef as ErdColumnRef exposing (ErdColumnRef)


type alias ErdRelation =
    { id : RelationId
    , name : RelationName
    , src : ErdColumnRef
    , ref : ErdColumnRef
    , origins : List Origin
    }


new : RelationName -> ErdColumnRef -> ErdColumnRef -> List Origin -> ErdRelation
new name src ref origins =
    ErdRelation (RelationId.new src ref) name src ref origins


create : Dict TableId Table -> Relation -> ErdRelation
create tables relation =
    { id = relation.id
    , name = relation.name
    , src = relation.src |> ErdColumnRef.create tables
    , ref = relation.ref |> ErdColumnRef.create tables
    , origins = relation.origins
    }


unpack : ErdRelation -> Relation
unpack relation =
    { id = relation.id
    , name = relation.name
    , src = relation.src |> ErdColumnRef.unpack
    , ref = relation.ref |> ErdColumnRef.unpack
    , origins = relation.origins
    }


label : SchemaName -> ErdRelation -> String
label defaultSchema relation =
    ColumnRef.show defaultSchema relation.src ++ " -> " ++ relation.name ++ " -> " ++ ColumnRef.show defaultSchema relation.ref
