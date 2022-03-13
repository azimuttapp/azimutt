module Models.Project.Relation exposing (Relation, RelationLike, clearOrigins, decode, encode, inOutRelation, merge, new, virtual, withLink, withRef, withSrc, withTableLink, withTableRef, withTableSrc)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef, ColumnRefLike)
import Models.Project.Origin as Origin exposing (Origin)
import Models.Project.RelationId as RelationId exposing (RelationId)
import Models.Project.RelationName as RelationName exposing (RelationName)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.TableId exposing (TableId)
import Services.Lenses exposing (setOrigins)


type alias Relation =
    { id : RelationId
    , name : RelationName
    , src : ColumnRef
    , ref : ColumnRef
    , origins : List Origin
    }


type alias RelationLike x y =
    { x
        | id : RelationId
        , name : RelationName
        , src : ColumnRefLike y
        , ref : ColumnRefLike y
        , origins : List Origin
    }


new : RelationName -> ColumnRef -> ColumnRef -> List Origin -> Relation
new name src ref origins =
    Relation (RelationId.new src ref) name src ref origins


virtual : ColumnRef -> ColumnRef -> SourceId -> Relation
virtual src ref source =
    new "virtual relation" src ref [ Origin source [] ]


inOutRelation : List (RelationLike x y) -> ColumnName -> List (RelationLike x y)
inOutRelation tableOutRelations column =
    tableOutRelations |> List.filter (\r -> r.src.column == column)


withTableSrc : TableId -> List (RelationLike x y) -> List (RelationLike x y)
withTableSrc table relations =
    relations |> List.filter (\r -> r.src.table == table)


withTableRef : TableId -> List (RelationLike x y) -> List (RelationLike x y)
withTableRef table relations =
    relations |> List.filter (\r -> r.ref.table == table)


withTableLink : TableId -> List (RelationLike x y) -> List (RelationLike x y)
withTableLink table relations =
    relations |> List.filter (\r -> (r.src.table == table) || (r.ref.table == table))


withSrc : TableId -> ColumnName -> List (RelationLike x y) -> List (RelationLike x y)
withSrc table column relations =
    relations |> List.filter (\r -> r.src.table == table && r.src.column == column)


withRef : TableId -> ColumnName -> List (RelationLike x y) -> List (RelationLike x y)
withRef table column relations =
    relations |> List.filter (\r -> r.ref.table == table && r.ref.column == column)


withLink : TableId -> ColumnName -> List (RelationLike x y) -> List (RelationLike x y)
withLink table column relations =
    relations |> List.filter (\r -> (r.src.table == table && r.src.column == column) || (r.ref.table == table && r.ref.column == column))


merge : Relation -> Relation -> Relation
merge r1 r2 =
    { id = r1.id
    , name = r1.name
    , src = r1.src
    , ref = r1.ref
    , origins = r1.origins ++ r2.origins
    }


clearOrigins : Relation -> Relation
clearOrigins relations =
    relations |> setOrigins []


encode : Relation -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> RelationName.encode )
        , ( "src", value.src |> ColumnRef.encode )
        , ( "ref", value.ref |> ColumnRef.encode )
        , ( "origins", value.origins |> Encode.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder Relation
decode =
    Decode.map4 new
        (Decode.field "name" RelationName.decode)
        (Decode.field "src" ColumnRef.decode)
        (Decode.field "ref" ColumnRef.decode)
        (Decode.defaultField "origins" (Decode.list Origin.decode) [])
