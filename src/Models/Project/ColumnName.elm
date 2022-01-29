module Models.Project.ColumnName exposing (ColumnName, decode, encode, merge, withName)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias ColumnName =
    -- needs to be comparable to be in Dict key
    String


withName : ColumnName -> String -> String
withName column text =
    text ++ "." ++ column


merge : ColumnName -> ColumnName -> ColumnName
merge n1 _ =
    n1


encode : ColumnName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder ColumnName
decode =
    Decode.string
