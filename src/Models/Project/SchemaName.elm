module Models.Project.SchemaName exposing (SchemaName, decode, encode, show)

import Conf
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias SchemaName =
    -- needs to be comparable to have TableId in Dict key
    String


show : SchemaName -> SchemaName -> SchemaName
show defaultSchema schema =
    if schema /= Conf.schema.empty then
        schema

    else if defaultSchema /= Conf.schema.empty then
        defaultSchema

    else
        "default"


encode : SchemaName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder SchemaName
decode =
    Decode.string
