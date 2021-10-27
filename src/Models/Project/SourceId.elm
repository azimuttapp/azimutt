module Models.Project.SourceId exposing (SourceId, decode, encode, new, toString)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Models exposing (UID)


type SourceId
    = SourceId UID


new : String -> SourceId
new id =
    SourceId id


toString : SourceId -> String
toString (SourceId id) =
    id


encode : SourceId -> Value
encode value =
    value |> toString |> Encode.string


decode : Decode.Decoder SourceId
decode =
    Decode.string |> Decode.map new
