module PagesComponents.Projects.Id_.Updates.Drag exposing (handleDrag, move)

import Conf
import Dict exposing (Dict)
import Libs.Area as Area exposing (Area)
import Libs.DomInfo exposing (DomInfo)
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.TableId as TableId
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.App.Updates.Helpers exposing (setCanvas, setCurrentLayout, setTableProps, setTables)
import PagesComponents.Projects.Id_.Models exposing (DragState, Model)


handleDrag : DragState -> Bool -> Model -> Model
handleDrag drag isEnd model =
    let
        canvas : CanvasProps
        canvas =
            model.project |> M.mapOrElse (.layout >> .canvas) { position = Position 0 0, zoom = 1 }
    in
    if drag.id == Conf.ids.erd then
        if isEnd then
            model |> setCurrentLayout (setCanvas (\c -> { c | position = c.position |> move drag 1 }))

        else
            model

    else if drag.id == Conf.ids.selectionBox then
        if isEnd then
            { model | selectionBox = Nothing }

        else
            model.domInfos
                |> buildSelectionArea canvas drag
                |> (\area ->
                        { model | selectionBox = Just area }
                            |> setCurrentLayout (setTables (List.map (\t -> { t | selected = Area.overlap area (model.domInfos |> tableArea t) })))
                   )

    else if isEnd then
        model |> setTableProps (TableId.fromHtmlId drag.id) (\t -> { t | position = t.position |> move drag canvas.zoom })

    else
        model


move : DragState -> ZoomLevel -> Position -> Position
move drag zoom position =
    position |> Position.add ((drag.last |> Position.sub drag.init) |> Position.div zoom)


buildSelectionArea : CanvasProps -> DragState -> Dict HtmlId DomInfo -> Area
buildSelectionArea canvas dragState domInfos =
    let
        erdPos : Position
        erdPos =
            domInfos |> Dict.get Conf.ids.erd |> M.mapOrElse .position (Position 0 0)
    in
    Area.from dragState.init dragState.last
        |> Area.move (erdPos |> Position.add canvas.position |> Position.negate)
        |> Area.div canvas.zoom


tableArea : TableProps -> Dict HtmlId DomInfo -> Area
tableArea table domInfos =
    domInfos
        |> Dict.get (TableId.toHtmlId table.id)
        |> M.mapOrElse (\domInfo -> { position = table.position, size = domInfo.size })
            { position = Position 0 0, size = Size 0 0 }
