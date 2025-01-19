module PagesComponents.Organization_.Project_.Models.LinkLayout exposing (LinkLayout, decode, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Tailwind as Tw exposing (Color)
import Models.Position as Position
import Models.Project.LayoutName as LayoutName exposing (LayoutName)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.LinkLayoutId exposing (LinkLayoutId)


type alias LinkLayout =
    { id : LinkLayoutId
    , target : LayoutName
    , position : Position.Grid
    , size : Size.Canvas
    , color : Maybe Color
    , selected : Bool
    }


encode : LinkLayout -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> Encode.int )
        , ( "target", value.target |> LayoutName.encode )
        , ( "position", value.position |> Position.encodeGrid )
        , ( "size", value.size |> Size.encodeCanvas )
        , ( "color", value.color |> Encode.maybe Tw.encodeColor )
        , ( "selected", value.selected |> Encode.withDefault Encode.bool False )
        ]


decode : Decoder LinkLayout
decode =
    Decode.map6 LinkLayout
        (Decode.field "id" Decode.int)
        (Decode.field "target" LayoutName.decode)
        (Decode.field "position" Position.decodeGrid)
        (Decode.field "size" Size.decodeCanvas)
        (Decode.maybeField "color" Tw.decodeColor)
        (Decode.defaultField "selected" Decode.bool False)
