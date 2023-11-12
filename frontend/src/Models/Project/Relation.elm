module Models.Project.Relation exposing (Relation, RelationLike, decode, encode, linkedToTable, new, outRelation, virtual)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef, ColumnRefLike)
import Models.Project.RelationId as RelationId exposing (RelationId)
import Models.Project.RelationName as RelationName exposing (RelationName)
import Models.Project.TableId exposing (TableId)


type alias Relation =
    { id : RelationId
    , name : RelationName
    , src : ColumnRef
    , ref : ColumnRef
    }


type alias RelationLike x y =
    { x
        | id : RelationId
        , name : RelationName
        , src : ColumnRefLike y
        , ref : ColumnRefLike y
    }


new : RelationName -> ColumnRef -> ColumnRef -> Relation
new name src ref =
    Relation (RelationId.new src ref) name src ref


virtual : ColumnRef -> ColumnRef -> Relation
virtual src ref =
    new "virtual relation" src ref


outRelation : List (RelationLike x y) -> ColumnPath -> List (RelationLike x y)
outRelation tableOutRelations column =
    tableOutRelations |> List.filter (\r -> r.src.column |> ColumnPath.startsWith column)


linkedToTable : TableId -> RelationLike x y -> Bool
linkedToTable table relation =
    relation.src.table == table || relation.ref.table == table


encode : Relation -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> RelationName.encode )
        , ( "src", value.src |> ColumnRef.encode )
        , ( "ref", value.ref |> ColumnRef.encode )
        ]


decode : Decode.Decoder Relation
decode =
    Decode.map3 new
        (Decode.field "name" RelationName.decode)
        (Decode.field "src" ColumnRef.decode)
        (Decode.field "ref" ColumnRef.decode)
