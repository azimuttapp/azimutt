module Libs.Models.Tag exposing (Tag, decode, encode, tagsFromString, tagsToString)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.String as String


type alias Tag =
    String


tagsToString : List Tag -> String
tagsToString tags =
    tags |> String.join ", "


tagsFromString : String -> List Tag
tagsFromString content =
    content |> String.split "," |> List.map String.trim |> List.filter String.nonEmpty


encode : Tag -> Value
encode value =
    Encode.string value


decode : Decode.Decoder Tag
decode =
    Decode.string
