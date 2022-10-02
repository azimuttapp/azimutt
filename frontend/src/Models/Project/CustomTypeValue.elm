module Models.Project.CustomTypeValue exposing (CustomTypeValue(..), decode, encode, merge)

import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Libs.Json.Encode as Encode
import Libs.List as List


type CustomTypeValue
    = Enum (List String)
    | Definition String


merge : CustomTypeValue -> CustomTypeValue -> CustomTypeValue
merge v1 v2 =
    case ( v1, v2 ) of
        ( Enum values1, Enum values2 ) ->
            Enum (values1 ++ values2 |> List.unique)

        _ ->
            v1


encode : CustomTypeValue -> Value
encode value =
    case value of
        Enum values ->
            Encode.notNullObject [ ( "enum", values |> Encode.list Encode.string ) ]

        Definition definition ->
            Encode.notNullObject [ ( "definition", definition |> Encode.string ) ]


decode : Decode.Decoder CustomTypeValue
decode =
    Decode.oneOf
        [ Decode.field "enum" (Decode.list Decode.string) |> Decode.map Enum
        , Decode.field "definition" Decode.string |> Decode.map Definition
        ]
