module Models.Project.Comment exposing (Comment, clearOrigins, decode, encode, merge)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Models.Project.Origin as Origin exposing (Origin)
import Services.Lenses exposing (setOrigins)


type alias Comment =
    { text : String
    , origins : List Origin
    }


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
        , ( "origins", value.origins |> Encode.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder Comment
decode =
    Decode.map2 Comment
        (Decode.field "text" Decode.string)
        (Decode.defaultField "origins" (Decode.list Origin.decode) [])
