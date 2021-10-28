module Models.Project.CanvasProps exposing (CanvasProps, decode, encode)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Json.Encode as E
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.ZoomLevel as ZoomLevel exposing (ZoomLevel)


type alias CanvasProps =
    { position : Position, zoom : ZoomLevel }


encode : CanvasProps -> Value
encode value =
    E.object
        [ ( "position", value.position |> Position.encode )
        , ( "zoom", value.zoom |> ZoomLevel.encode )
        ]


decode : Decode.Decoder CanvasProps
decode =
    Decode.map2 CanvasProps
        (Decode.field "position" Position.decode)
        (Decode.field "zoom" ZoomLevel.decode)
