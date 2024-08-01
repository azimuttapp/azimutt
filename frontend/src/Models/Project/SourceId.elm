module Models.Project.SourceId exposing (SourceId, SourceIdStr, decode, decodeStr, dictGet, encode, encodeStr, fromString, generator, new, one, toString, two, zero)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Value)
import Libs.Models.Uuid as Uuid exposing (Uuid)
import Random


type SourceId
    = SourceId Uuid


type alias SourceIdStr =
    Uuid


zero : SourceId
zero =
    SourceId Uuid.zero


one : SourceId
one =
    SourceId Uuid.one


two : SourceId
two =
    SourceId Uuid.two


new : String -> SourceId
new id =
    -- only for tests
    SourceId id


generator : Random.Generator SourceId
generator =
    Uuid.generator |> Random.map new


toString : SourceId -> SourceIdStr
toString (SourceId id) =
    id


fromString : SourceIdStr -> Maybe SourceId
fromString value =
    if Uuid.isValid value then
        Just (new value)

    else
        Nothing


dictGet : SourceId -> Dict SourceIdStr a -> Maybe a
dictGet id dict =
    dict |> Dict.get (toString id)


encode : SourceId -> Value
encode value =
    value |> toString |> encodeStr


decode : Decode.Decoder SourceId
decode =
    decodeStr |> Decode.map new


encodeStr : SourceIdStr -> Value
encodeStr value =
    value |> Uuid.encode


decodeStr : Decode.Decoder SourceIdStr
decodeStr =
    Uuid.decode
