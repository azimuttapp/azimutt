module PagesComponents.Organization_.Project_.Models.Erd.RelationWithOrigin exposing (RelationWithOrigin, create, merge, unpack)

import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Relation exposing (Relation)
import Models.Project.RelationId exposing (RelationId)
import Models.Project.RelationName exposing (RelationName)
import Models.Project.Source exposing (Source)
import PagesComponents.Organization_.Project_.Models.ErdOrigin as ErdOrigin exposing (ErdOrigin)


type alias RelationWithOrigin =
    { id : RelationId
    , name : RelationName
    , src : ColumnRef
    , ref : ColumnRef
    , origins : List ErdOrigin
    }


create : Source -> Relation -> RelationWithOrigin
create source relation =
    { id = relation.id
    , name = relation.name
    , src = relation.src
    , ref = relation.ref
    , origins = [ ErdOrigin.create source ]
    }


unpack : RelationWithOrigin -> Relation
unpack relation =
    { id = relation.id
    , name = relation.name
    , src = relation.src
    , ref = relation.ref
    }


merge : RelationWithOrigin -> RelationWithOrigin -> RelationWithOrigin
merge r1 r2 =
    { id = r1.id
    , name = r1.name
    , src = r1.src
    , ref = r1.ref
    , origins = r1.origins ++ r2.origins
    }
