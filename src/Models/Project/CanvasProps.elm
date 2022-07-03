module Models.Project.CanvasProps exposing (CanvasProps, adapt, decode, empty, encode, viewport)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Area as Area exposing (Area)
import Libs.Json.Encode as Encode
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.ZoomLevel as ZoomLevel exposing (ZoomLevel)
import Models.Project.GridPosition as GridPosition
import Models.ScreenProps exposing (ScreenProps)


type alias CanvasProps =
    { position : Position, zoom : ZoomLevel }


empty : CanvasProps
empty =
    { position = Position.zero, zoom = 1 }


adapt : ScreenProps -> CanvasProps -> Position -> Position
adapt screen canvas pos =
    pos |> Position.sub screen.position |> Position.sub canvas.position |> Position.div canvas.zoom


viewport : ScreenProps -> CanvasProps -> Area
viewport screen canvas =
    Area (canvas.position |> Position.negate) screen.size |> Area.div canvas.zoom


encode : CanvasProps -> Value
encode value =
    Encode.notNullObject
        [ ( "position", value.position |> GridPosition.encode )
        , ( "zoom", value.zoom |> ZoomLevel.encode )
        ]


decode : Decode.Decoder CanvasProps
decode =
    Decode.map2 CanvasProps
        (Decode.field "position" GridPosition.decode)
        (Decode.field "zoom" ZoomLevel.decode)
