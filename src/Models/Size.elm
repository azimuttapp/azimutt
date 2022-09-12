module Models.Size exposing (Canvas, Viewport, buildCanvas, buildViewport, decodeCanvas, decodeViewport, diffCanvas, divCanvas, divViewport, encodeCanvas, extractCanvas, extractViewport, ratioCanvas, stylesCanvas, subCanvas, toTupleCanvas, toTupleViewport, viewportToCanvas, zeroCanvas, zeroViewport)

import Html exposing (Attribute)
import Html.Attributes exposing (style)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode
import Libs.Models.Delta exposing (Delta)
import Libs.Models.Size as Size exposing (Size)
import Libs.Models.ZoomLevel exposing (ZoomLevel)


type Viewport
    = Viewport Size -- size in the browser viewport, change with zoom


type Canvas
    = Canvas Size -- size in the canvas, doesn't change with zoom


buildViewport : Size -> Viewport
buildViewport pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> Viewport


extractViewport : Viewport -> Size
extractViewport (Viewport size) =
    -- use it only in last resort in very narrow and explicit scope
    size


buildCanvas : Size -> Canvas
buildCanvas pos =
    -- use it only in last resort in very narrow and explicit scope
    pos |> Canvas


extractCanvas : Canvas -> Size
extractCanvas (Canvas size) =
    -- use it only in last resort in very narrow and explicit scope
    size


zeroViewport : Viewport
zeroViewport =
    Viewport Size.zero


zeroCanvas : Canvas
zeroCanvas =
    Canvas Size.zero


subCanvas : Float -> Canvas -> Canvas
subCanvas amount (Canvas size) =
    size |> Size.sub amount |> buildCanvas


divViewport : Float -> Viewport -> Viewport
divViewport factor (Viewport size) =
    size |> Size.div factor |> buildViewport


divCanvas : Float -> Canvas -> Canvas
divCanvas factor (Canvas size) =
    size |> Size.div factor |> buildCanvas


diffCanvas : Canvas -> Canvas -> Delta
diffCanvas (Canvas b) (Canvas a) =
    Size.diff b a


ratioCanvas : Canvas -> Canvas -> Delta
ratioCanvas (Canvas b) (Canvas a) =
    Size.ratio b a


viewportToCanvas : ZoomLevel -> Viewport -> Canvas
viewportToCanvas zoom (Viewport size) =
    size |> Size.div zoom |> buildCanvas


toTupleViewport : Viewport -> ( Float, Float )
toTupleViewport (Viewport size) =
    size |> Size.toTuple


toTupleCanvas : Canvas -> ( Float, Float )
toTupleCanvas (Canvas size) =
    size |> Size.toTuple


stylesCanvas : Canvas -> List (Attribute msg)
stylesCanvas (Canvas size) =
    [ style "width" (String.fromFloat size.width ++ "px"), style "height" (String.fromFloat size.height ++ "px") ]


encodeCanvas : Canvas -> Value
encodeCanvas (Canvas size) =
    Encode.notNullObject
        [ ( "width", size.width |> Encode.float )
        , ( "height", size.height |> Encode.float )
        ]


decodeCanvas : Decode.Decoder Canvas
decodeCanvas =
    Decode.map2 (\w h -> Size w h |> buildCanvas)
        (Decode.field "width" Decode.float)
        (Decode.field "height" Decode.float)


decodeViewport : Decode.Decoder Viewport
decodeViewport =
    Decode.map2 (\w h -> Size w h |> buildViewport)
        (Decode.field "width" Decode.float)
        (Decode.field "height" Decode.float)
