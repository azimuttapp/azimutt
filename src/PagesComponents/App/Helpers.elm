module PagesComponents.App.Helpers exposing (pagePosToCanvasPos)

import Conf exposing (conf)
import Dict exposing (Dict)
import Libs.DomInfo exposing (DomInfo)
import Libs.Models exposing (HtmlId)
import Libs.Position as Position exposing (Position)
import Models.Project exposing (CanvasProps)


pagePosToCanvasPos : Dict HtmlId DomInfo -> CanvasProps -> Position -> Position
pagePosToCanvasPos domInfos canvas pos =
    let
        erdPos : Position
        erdPos =
            domInfos |> Dict.get conf.ids.erd |> Maybe.map .position |> Maybe.withDefault (Position 0 0)
    in
    pos |> Position.sub erdPos |> Position.sub canvas.position |> Position.div canvas.zoom
