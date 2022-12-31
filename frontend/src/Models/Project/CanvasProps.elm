module Models.Project.CanvasProps exposing (CanvasProps, decode, empty, encode, eventCanvas, viewport)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Html.Events exposing (PointerEvent)
import Libs.Json.Encode as Encode
import Libs.Models.ZoomLevel as ZoomLevel exposing (ZoomLevel)
import Models.Area as Area
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Size as Size


type alias CanvasProps =
    { position : Position.Diagram -- the position of the canvas in the erd
    , zoom : ZoomLevel
    }


empty : CanvasProps
empty =
    { position = Position.zeroDiagram, zoom = 1 }


viewport : ErdProps -> CanvasProps -> Area.Canvas
viewport erdElem canvas =
    -- compute the canvas viewport (the visible area of the canvas)
    Area.Diagram Position.zeroDiagram (erdElem.size |> Size.viewportToCanvas canvas.zoom)
        |> Area.diagramToCanvas canvas.position


eventCanvas : ErdProps -> CanvasProps -> PointerEvent -> Position.Canvas
eventCanvas erdElem canvasProps event =
    event.clientPos |> Position.viewportToCanvas erdElem.position canvasProps.position canvasProps.zoom


encode : CanvasProps -> Value
encode value =
    Encode.notNullObject
        [ ( "position", value.position |> Position.encodeDiagram )
        , ( "zoom", value.zoom |> ZoomLevel.encode )
        ]


decode : Decode.Decoder CanvasProps
decode =
    Decode.map2 CanvasProps
        (Decode.field "position" Position.decodeDiagram)
        (Decode.field "zoom" ZoomLevel.decode)
