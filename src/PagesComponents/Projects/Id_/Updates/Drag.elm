module PagesComponents.Projects.Id_.Updates.Drag exposing (handleDrag, move)

import Conf
import Libs.Area as Area exposing (Area)
import Libs.Maybe as M
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId as TableId
import Models.Project.TableProps as TableProps
import PagesComponents.Projects.Id_.Models exposing (DragState, Model)
import Services.Lenses exposing (setCanvas, setCurrentLayout, setTableProps, setTables)


handleDrag : DragState -> Bool -> Model -> Model
handleDrag drag isEnd model =
    let
        canvas : CanvasProps
        canvas =
            model.project |> M.mapOrElse (.layout >> .canvas) CanvasProps.zero
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
            drag
                |> buildSelectionArea canvas
                |> (\area ->
                        { model | selectionBox = Just area }
                            |> setCurrentLayout (setTables (List.map (\t -> { t | selected = Area.overlap area (t |> TableProps.area) })))
                   )

    else if isEnd then
        model |> setTableProps (TableId.fromHtmlId drag.id) (\t -> { t | position = t.position |> move drag canvas.zoom })

    else
        model


move : DragState -> ZoomLevel -> Position -> Position
move drag zoom position =
    position |> Position.add ((drag.last |> Position.sub drag.init) |> Position.div zoom)


buildSelectionArea : CanvasProps -> DragState -> Area
buildSelectionArea canvas dragState =
    Area.from dragState.init dragState.last
        |> Area.move (canvas.origin |> Position.add canvas.position |> Position.negate)
        |> Area.div canvas.zoom
