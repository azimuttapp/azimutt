module Models.Project.TableName exposing (TableName, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias TableName =
    -- needs to be comparable to have TableId in Dict key
    String


encode : TableName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder TableName
decode =
    Decode.string
