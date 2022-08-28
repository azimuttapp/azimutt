module Models.Project.CanvasProps exposing (CanvasProps, decode, empty, encode, viewport)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Json.Encode as Encode
import Libs.Models.ZoomLevel as ZoomLevel exposing (ZoomLevel)
import Models.Area as Area
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position


type alias CanvasProps =
    { position : Position.Canvas -- the position of the canvas in the erd
    , zoom : ZoomLevel
    }


empty : CanvasProps
empty =
    { position = Position.zeroCanvas, zoom = 1 }


viewport : ErdProps -> CanvasProps -> Area.InCanvas
viewport erdElem canvas =
    -- compute the canvas viewport (the visible area of the canvas)
    Area.Canvas Position.zeroCanvas erdElem.size |> Area.canvasToInCanvas canvas.position canvas.zoom


encode : CanvasProps -> Value
encode value =
    Encode.notNullObject
        [ ( "position", value.position |> Position.encodeCanvas )
        , ( "zoom", value.zoom |> ZoomLevel.encode )
        ]


decode : Decode.Decoder CanvasProps
decode =
    Decode.map2 CanvasProps
        (Decode.field "position" Position.decodeCanvas)
        (Decode.field "zoom" ZoomLevel.decode)
