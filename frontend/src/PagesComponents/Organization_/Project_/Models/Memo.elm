module PagesComponents.Organization_.Project_.Models.Memo exposing (Memo, decode, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode
import Models.Position as Position
import Models.Size as Size


type alias Memo =
    { content : String
    , position : Position.CanvasGrid
    , size : Size.Canvas

    -- , edits : List ( Time.Posix, Maybe UserId )
    }


encode : Memo -> Value
encode value =
    Encode.notNullObject
        [ ( "content", value.content |> Encode.string )
        , ( "position", value.position |> Position.encodeGrid )
        , ( "size", value.size |> Size.encodeCanvas )
        ]


decode : Decoder Memo
decode =
    Decode.map3 Memo
        (Decode.field "content" Decode.string)
        (Decode.field "position" Position.decodeGrid)
        (Decode.field "size" Size.decodeCanvas)
