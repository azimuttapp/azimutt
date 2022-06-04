module Models.Project.SourceId exposing (SourceId, decode, encode, new, toString)

import Json.Decode as Decode exposing (Value)
import Libs.Models.Uuid as Uuid exposing (Uuid)


type SourceId
    = SourceId Uuid


new : String -> SourceId
new id =
    SourceId id


toString : SourceId -> String
toString (SourceId id) =
    id


encode : SourceId -> Value
encode value =
    value |> toString |> Uuid.encode


decode : Decode.Decoder SourceId
decode =
    Uuid.decode |> Decode.map new
