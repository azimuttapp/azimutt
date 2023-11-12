module Models.Project.CustomType exposing (CustomType, decode, encode, new)

import Json.Decode as Decode exposing (Value)
import Libs.Json.Encode as Encode
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.CustomTypeName as CustomTypeName exposing (CustomTypeName)
import Models.Project.CustomTypeValue as CustomTypeValue exposing (CustomTypeValue)
import Models.Project.SchemaName as SchemaName exposing (SchemaName)


type alias CustomType =
    { id : CustomTypeId
    , name : CustomTypeName
    , value : CustomTypeValue
    }


new : SchemaName -> CustomTypeName -> CustomTypeValue -> CustomType
new schema name value =
    CustomType ( schema, name ) name value


encode : CustomType -> Value
encode value =
    Encode.notNullObject
        [ ( "schema", value.id |> Tuple.first |> SchemaName.encode )
        , ( "name", value.name |> CustomTypeName.encode )
        , ( "value", value.value |> CustomTypeValue.encode )
        ]


decode : Decode.Decoder CustomType
decode =
    Decode.map3 new
        (Decode.field "schema" SchemaName.decode)
        (Decode.field "name" CustomTypeName.decode)
        (Decode.field "value" CustomTypeValue.decode)
