module Models.Project.SourceId exposing (SourceId, decode, encode, new, random, toString)

import Json.Decode as Decode exposing (Value)
import Libs.Models.Uuid as Uuid exposing (Uuid)
import Random


type SourceId
    = SourceId Uuid


new : String -> SourceId
new id =
    SourceId id


random : Random.Seed -> ( SourceId, Random.Seed )
random seed =
    seed |> Uuid.random |> Tuple.mapFirst new


toString : SourceId -> String
toString (SourceId id) =
    id


encode : SourceId -> Value
encode value =
    value |> toString |> Uuid.encode


decode : Decode.Decoder SourceId
decode =
    Uuid.decode |> Decode.map new
