module Models.Project.Relation exposing (Relation, decode, encode, inOutRelation, new, virtual)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.Origin as Origin exposing (Origin)
import Models.Project.RelationId as RelationId exposing (RelationId)
import Models.Project.RelationName as RelationName exposing (RelationName)
import Models.Project.SourceId exposing (SourceId)


type alias Relation =
    { id : RelationId, name : RelationName, src : ColumnRef, ref : ColumnRef, origins : List Origin }


new : RelationName -> ColumnRef -> ColumnRef -> List Origin -> Relation
new name src ref origins =
    Relation (RelationId.new src ref) name src ref origins


virtual : ColumnRef -> ColumnRef -> SourceId -> Relation
virtual src ref source =
    new "virtual relation" src ref [ Origin source [] ]


inOutRelation : List Relation -> ColumnName -> List Relation
inOutRelation tableOutRelations column =
    tableOutRelations |> List.filter (\r -> r.src.column == column)


encode : Relation -> Value
encode value =
    E.object
        [ ( "name", value.name |> RelationName.encode )
        , ( "src", value.src |> ColumnRef.encode )
        , ( "ref", value.ref |> ColumnRef.encode )
        , ( "origins", value.origins |> E.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder Relation
decode =
    Decode.map4 new
        (Decode.field "name" RelationName.decode)
        (Decode.field "src" ColumnRef.decode)
        (Decode.field "ref" ColumnRef.decode)
        (D.defaultField "origins" (Decode.list Origin.decode) [])
