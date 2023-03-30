module DataSources.JsonMiner.JsonGenerator exposing (generate)

import DataSources.JsonMiner.JsonAdapter as JsonAdapter
import DataSources.JsonMiner.JsonSchema as JsonSchema
import Dict
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode
import Models.Project.CustomType as CustomType
import Models.Project.Relation as Relation
import Models.Project.Schema exposing (Schema)
import Models.Project.Table as Table


generate : Schema -> String
generate schema =
    schema |> JsonAdapter.unpackSchema |> JsonSchema.encode |> Encode.encode 2


encode : Schema -> Value
encode value =
    -- encoder similar as Source, should migrate to it for JSON import
    Encode.notNullObject
        [ ( "tables", value.tables |> Dict.values |> Encode.list Table.encode )
        , ( "relations", value.relations |> Encode.list Relation.encode )
        , ( "types", value.types |> Dict.values |> Encode.withDefault (Encode.list CustomType.encode) [] )
        ]
