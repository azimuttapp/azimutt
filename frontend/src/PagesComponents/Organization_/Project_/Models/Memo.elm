module PagesComponents.Organization_.Project_.Models.Memo exposing (Memo, MemoId, decode, encode, htmlId, htmlIdPrefix)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode
import Libs.Models.HtmlId exposing (HtmlId)
import Models.Position as Position
import Models.Size as Size


type alias MemoId =
    Int


type alias Memo =
    { id : MemoId
    , content : String
    , position : Position.CanvasGrid
    , size : Size.Canvas

    -- , edits : List ( Time.Posix, Maybe UserId )
    }


htmlIdPrefix : HtmlId
htmlIdPrefix =
    "az-memo-"


htmlId : Int -> HtmlId
htmlId id =
    htmlIdPrefix ++ String.fromInt id


encode : Memo -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> Encode.int )
        , ( "content", value.content |> Encode.string )
        , ( "position", value.position |> Position.encodeGrid )
        , ( "size", value.size |> Size.encodeCanvas )
        ]


decode : Decoder Memo
decode =
    Decode.map4 Memo
        (Decode.field "id" Decode.int)
        (Decode.field "content" Decode.string)
        (Decode.field "position" Position.decodeGrid)
        (Decode.field "size" Size.decodeCanvas)
