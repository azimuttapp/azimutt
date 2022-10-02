module Models.Project.LayoutName exposing (LayoutName, decode, encode, fromString, toString)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type alias LayoutName =
    -- needs to be comparable to be in Dict key
    String


toString : LayoutName -> String
toString name =
    name


fromString : String -> LayoutName
fromString name =
    name


encode : LayoutName -> Value
encode value =
    Encode.string value


decode : Decode.Decoder LayoutName
decode =
    Decode.string
