module Models.Project.Comment exposing (Comment, decode, encode, short)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Bool as Bool
import Libs.Json.Encode as Encode


type alias Comment =
    { text : String
    }


short : String -> String
short content =
    let
        trimmed : String
        trimmed =
            content |> String.trim
    in
    trimmed
        |> String.split "\n"
        |> List.head
        |> Maybe.withDefault ""
        |> String.left 50
        |> (\show -> Bool.cond (show == trimmed) show (show ++ "… double click to see all"))


encode : Comment -> Value
encode value =
    Encode.notNullObject
        [ ( "text", value.text |> Encode.string )
        ]


decode : Decode.Decoder Comment
decode =
    Decode.map Comment
        (Decode.field "text" Decode.string)
