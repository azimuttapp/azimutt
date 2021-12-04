module PagesComponents.App.Helpers exposing (pagePosToCanvasPos)

import Conf
import Dict exposing (Dict)
import Libs.DomInfo exposing (DomInfo)
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position exposing (Position)
import Models.Project.CanvasProps exposing (CanvasProps)


pagePosToCanvasPos : Dict HtmlId DomInfo -> CanvasProps -> Position -> Position
pagePosToCanvasPos domInfos canvas pos =
    let
        erdPos : Position
        erdPos =
            domInfos |> Dict.get Conf.ids.erd |> M.mapOrElse .position (Position 0 0)
    in
    pos |> Position.sub erdPos |> Position.sub canvas.position |> Position.div canvas.zoom
