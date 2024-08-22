module Models.Project.ColumnName exposing (ColumnName, decode, dictGetI, encode)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Dict as Dict
import Libs.Maybe as Maybe


type alias ColumnName =
    -- needs to be comparable to be in Dict key
    String


dictGetI : ColumnName -> Dict ColumnName a -> Maybe a
dictGetI name dict =
    (dict |> Dict.get name)
        |> Maybe.orElse (name |> String.toLower |> (\lowerName -> dict |> Dict.find (\k _ -> String.toLower k == lowerName)))


encode : ColumnName -> Value
encode value =
    value |> Encode.string


decode : Decoder ColumnName
decode =
    Decode.string
