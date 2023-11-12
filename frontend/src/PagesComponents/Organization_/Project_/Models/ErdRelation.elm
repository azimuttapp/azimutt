module PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation, create, label, linkedTo, new, unpack)

import Dict exposing (Dict)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.Relation exposing (Relation)
import Models.Project.RelationId as RelationId exposing (RelationId)
import Models.Project.RelationName exposing (RelationName)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models.Erd.RelationWithOrigin exposing (RelationWithOrigin)
import PagesComponents.Organization_.Project_.Models.Erd.TableWithOrigin exposing (TableWithOrigin)
import PagesComponents.Organization_.Project_.Models.ErdColumnRef as ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Organization_.Project_.Models.ErdOrigin exposing (ErdOrigin)


type alias ErdRelation =
    { id : RelationId
    , name : RelationName
    , src : ErdColumnRef
    , ref : ErdColumnRef
    , origins : List ErdOrigin
    }


new : RelationName -> ErdColumnRef -> ErdColumnRef -> List ErdOrigin -> ErdRelation
new name src ref origins =
    ErdRelation (RelationId.new src ref) name src ref origins


create : Dict TableId TableWithOrigin -> RelationWithOrigin -> ErdRelation
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
    }


label : SchemaName -> ErdRelation -> String
label defaultSchema relation =
    ColumnRef.show defaultSchema relation.src ++ " -> " ++ relation.name ++ " -> " ++ ColumnRef.show defaultSchema relation.ref


linkedTo : ColumnRef -> ErdRelation -> Bool
linkedTo column relation =
    (relation.src.table == column.table && relation.src.column == column.column) || (relation.ref.table == column.table && relation.ref.column == column.column)
