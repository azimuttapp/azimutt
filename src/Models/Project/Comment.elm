module Models.Project.Comment exposing (Comment, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Models.Project.Origin as Origin exposing (Origin)


type alias Comment =
    { text : String, origins : List Origin }


encode : Comment -> Value
encode value =
    E.object
        [ ( "text", value.text |> Encode.string )
        , ( "origins", value.origins |> E.withDefault (Encode.list Origin.encode) [] )
        ]


decode : Decode.Decoder Comment
decode =
    Decode.map2 Comment
        (Decode.field "text" Decode.string)
        (D.defaultField "origins" (Decode.list Origin.decode) [])
