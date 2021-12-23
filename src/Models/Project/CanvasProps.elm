module Models.Project.CanvasProps exposing (CanvasProps, adapt, decode, encode)

import Conf
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.DomInfo exposing (DomInfo)
import Libs.Json.Encode as E
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.ZoomLevel as ZoomLevel exposing (ZoomLevel)


type alias CanvasProps =
    { position : Position, zoom : ZoomLevel }


adapt : CanvasProps -> Dict HtmlId DomInfo -> Position -> Position
adapt canvas domInfos pos =
    let
        erdPos : Position
        erdPos =
            domInfos |> Dict.get Conf.ids.erd |> M.mapOrElse .position (Position 0 0)
    in
    pos |> Position.sub erdPos |> Position.sub canvas.position |> Position.div canvas.zoom


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
