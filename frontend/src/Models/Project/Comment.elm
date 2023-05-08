module Models.Project.Comment exposing (Comment, clearOrigins, decode, encode, merge, short)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Bool as Bool
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Models.Project.Origin as Origin exposing (Origin)
import Services.Lenses exposing (setOrigins)


type alias Comment =
    { text : String
    , origins : List Origin
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


merge : Comment -> Comment -> Comment
merge c1 c2 =
    { text = c1.text
    , origins = c1.origins ++ c2.origins
    }


clearOrigins : Comment -> Comment
clearOrigins comment =
    comment |> setOrigins []


encode : Comment -> Value
encode value =
    Encode.notNullObject
        [ ( "text", value.text |> Encode.string )
        , ( "origins", value.origins |> Origin.encodeList )
        ]


decode : Decode.Decoder Comment
decode =
    Decode.map2 Comment
        (Decode.field "text" Decode.string)
        (Decode.defaultField "origins" (Decode.list Origin.decode) [])
