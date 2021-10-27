module Models.Project.CanvasProps exposing (CanvasProps, decode, encode)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Json.Encode as E
import Libs.Json.Formats exposing (decodePosition, decodeZoomLevel, encodePosition, encodeZoomLevel)
import Libs.Models exposing (ZoomLevel)
import Libs.Position exposing (Position)


type alias CanvasProps =
    { position : Position, zoom : ZoomLevel }


encode : CanvasProps -> Value
encode value =
    E.object
        [ ( "position", value.position |> encodePosition )
        , ( "zoom", value.zoom |> encodeZoomLevel )
        ]


decode : Decode.Decoder CanvasProps
decode =
    Decode.map2 CanvasProps
        (Decode.field "position" decodePosition)
        (Decode.field "zoom" decodeZoomLevel)
