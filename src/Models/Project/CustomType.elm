module Models.Project.CustomType exposing (CustomType, decode, encode, merge)

import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.CustomTypeName as CustomTypeName exposing (CustomTypeName)
import Models.Project.Origin as Origin exposing (Origin)
import Models.Project.SchemaName as SchemaName


type alias CustomType =
    { id : CustomTypeId
    , name : CustomTypeName
    , definition : String
    , origins : List Origin
    }


merge : CustomType -> CustomType -> CustomType
merge t1 t2 =
    { id = t1.id
    , name = t1.name
    , definition = t1.definition
    , origins = t1.origins ++ t2.origins
    }


encode : CustomType -> Value
encode value =
    Encode.notNullObject
        [ ( "schema", value.id |> Tuple.first |> SchemaName.encode )
        , ( "name", value.name |> CustomTypeName.encode )
        , ( "definition", value.definition |> Encode.string )
        , ( "origins", value.origins |> Encode.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder CustomType
decode =
    Decode.map4 (\s n d o -> CustomType ( s, n ) n d o)
        (Decode.field "schema" SchemaName.decode)
        (Decode.field "name" CustomTypeName.decode)
        (Decode.field "definition" Decode.string)
        (Decode.defaultField "origins" (Decode.list Origin.decode) [])
