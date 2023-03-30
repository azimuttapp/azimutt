module Models.Project.Schema exposing (Schema, filter, from)

import Dict exposing (Dict)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Set exposing (Set)


type alias Schema =
    { tables : Dict TableId Table, relations : List Relation, types : Dict CustomTypeId CustomType }


from : { s | tables : Dict TableId Table, relations : List Relation, types : Dict CustomTypeId CustomType } -> Schema
from source =
    { tables = source.tables, relations = source.relations, types = source.types }


filter : List TableId -> Schema -> Schema
filter ids schema =
    let
        tables : Set TableId
        tables =
            Set.fromList ids
    in
    { tables = schema.tables |> Dict.filter (\k _ -> tables |> Set.member k)
    , relations = schema.relations |> List.filter (\r -> (tables |> Set.member r.src.table) && (tables |> Set.member r.ref.table))
    , types = schema.types
    }
