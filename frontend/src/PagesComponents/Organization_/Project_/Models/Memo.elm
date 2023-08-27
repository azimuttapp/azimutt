module PagesComponents.Organization_.Project_.Models.Memo exposing (Memo, decode, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Tailwind as Tw exposing (Color)
import Models.Position as Position
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.MemoId exposing (MemoId)


type alias Memo =
    { id : MemoId
    , content : String
    , position : Position.Grid
    , size : Size.Canvas
    , color : Maybe Color
    , selected : Bool
    }


encode : Memo -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> Encode.int )
        , ( "content", value.content |> Encode.string )
        , ( "position", value.position |> Position.encodeGrid )
        , ( "size", value.size |> Size.encodeCanvas )
        , ( "color", value.color |> Encode.maybe Tw.encodeColor )
        , ( "selected", value.selected |> Encode.withDefault Encode.bool False )
        ]


decode : Decoder Memo
decode =
    Decode.map6 Memo
        (Decode.field "id" Decode.int)
        (Decode.field "content" Decode.string)
        (Decode.field "position" Position.decodeGrid)
        (Decode.field "size" Size.decodeCanvas)
        (Decode.maybeField "color" Tw.decodeColor)
        (Decode.defaultField "selected" Decode.bool False)
