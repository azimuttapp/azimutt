module Models.Project.CanvasProps exposing (CanvasProps, adapt, decode, encode, viewport, zero)

import Conf
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode exposing (Value)
import Libs.Area as Area exposing (Area)
import Libs.DomInfo exposing (DomInfo)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Libs.Models.ZoomLevel as ZoomLevel exposing (ZoomLevel)


type alias CanvasProps =
    { origin : Position, size : Size, position : Position, zoom : ZoomLevel }


zero : CanvasProps
zero =
    { origin = Position.zero, size = Size.zero, position = Position.zero, zoom = 1 }


adapt : CanvasProps -> Dict HtmlId DomInfo -> Position -> Position
adapt canvas domInfos pos =
    let
        erdPos : Position
        erdPos =
            domInfos |> Dict.get Conf.ids.erd |> M.mapOrElse .position Position.zero
    in
    -- FIXME: domInfos and origin are the same thing, the first one is set in old app and the other one on the new app
    pos |> Position.sub erdPos |> Position.sub canvas.origin |> Position.sub canvas.position |> Position.div canvas.zoom


viewport : CanvasProps -> Area
viewport canvas =
    Area (canvas.position |> Position.negate) canvas.size |> Area.div canvas.zoom


encode : CanvasProps -> Value
encode value =
    -- origin and size should be re-computed
    E.object
        [ ( "position", value.position |> Position.encode )
        , ( "zoom", value.zoom |> ZoomLevel.encode )
        ]


decode : Decode.Decoder CanvasProps
decode =
    Decode.map4 CanvasProps
        (D.defaultField "origin" Position.decode Position.zero)
        (D.defaultField "size" Size.decode Size.zero)
        (Decode.field "position" Position.decode)
        (Decode.field "zoom" ZoomLevel.decode)
