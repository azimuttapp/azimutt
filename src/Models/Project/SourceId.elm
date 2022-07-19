module Models.Project.SourceId exposing (SourceId, decode, encode, fromString, generator, new, toString)

import Json.Decode as Decode exposing (Value)
import Libs.Models.Uuid as Uuid exposing (Uuid)
import Random


type SourceId
    = SourceId Uuid


new : String -> SourceId
new id =
    SourceId id


generator : Random.Generator SourceId
generator =
    Uuid.generator |> Random.map new


toString : SourceId -> String
toString (SourceId id) =
    id


fromString : String -> Maybe SourceId
fromString value =
    if Uuid.isValid value then
        Just (new value)

    else
        Nothing


encode : SourceId -> Value
encode value =
    value |> toString |> Uuid.encode


decode : Decode.Decoder SourceId
decode =
    Uuid.decode |> Decode.map new
