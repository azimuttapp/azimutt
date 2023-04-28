module Libs.Models.Notes exposing (Notes, NotesKey, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias Notes =
    -- documentation notes with markdown formatting
    String


type alias NotesKey =
    -- legacy type to read old notes stored in they own property
    String


encode : Notes -> Value
encode value =
    Encode.string value


decode : Decode.Decoder Notes
decode =
    Decode.string
