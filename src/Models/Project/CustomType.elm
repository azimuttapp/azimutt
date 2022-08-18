module Models.Project.CustomType exposing (CustomType, decode, def, encode, enum, merge, new)

import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.CustomTypeName as CustomTypeName exposing (CustomTypeName)
import Models.Project.CustomTypeValue as CustomTypeValue exposing (CustomTypeValue)
import Models.Project.Origin as Origin exposing (Origin)
import Models.Project.SchemaName as SchemaName exposing (SchemaName)


type alias CustomType =
    { id : CustomTypeId
    , name : CustomTypeName
    , value : CustomTypeValue
    , origins : List Origin
    }


new : SchemaName -> CustomTypeName -> CustomTypeValue -> List Origin -> CustomType
new schema name value origins =
    CustomType ( schema, name ) name value origins


enum : SchemaName -> CustomTypeName -> List String -> List Origin -> CustomType
enum schema name value origins =
    new schema name (CustomTypeValue.Enum value) origins


def : SchemaName -> CustomTypeName -> String -> List Origin -> CustomType
def schema name value origins =
    new schema name (CustomTypeValue.Definition value) origins


merge : CustomType -> CustomType -> CustomType
merge t1 t2 =
    { id = t1.id
    , name = t1.name
    , value = CustomTypeValue.merge t1.value t2.value
    , origins = t1.origins ++ t2.origins
    }


encode : CustomType -> Value
encode value =
    Encode.notNullObject
        [ ( "schema", value.id |> Tuple.first |> SchemaName.encode )
        , ( "name", value.name |> CustomTypeName.encode )
        , ( "value", value.value |> CustomTypeValue.encode )
        , ( "origins", value.origins |> Encode.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder CustomType
decode =
    Decode.map4 new
        (Decode.field "schema" SchemaName.decode)
        (Decode.field "name" CustomTypeName.decode)
        (Decode.field "value" CustomTypeValue.decode)
        (Decode.defaultField "origins" (Decode.list Origin.decode) [])
