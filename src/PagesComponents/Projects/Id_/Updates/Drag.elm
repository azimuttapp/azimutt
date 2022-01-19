module PagesComponents.Projects.Id_.Updates.Drag exposing (handleDrag, moveCanvas, moveTables, moveTables2)

import Conf
import Dict exposing (Dict)
import Libs.Area as Area exposing (Area)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableProps as TableProps exposing (TableProps)
import Models.ScreenProps exposing (ScreenProps)
import PagesComponents.Projects.Id_.Models exposing (DragState, Model)
import PagesComponents.Projects.Id_.Models.Erd exposing (ErdTableProps, setErdTablePropsPosition)
import Services.Lenses exposing (setCanvas, setCurrentLayout, setErd, setLayoutTables, setTableProps, setTables)


handleDrag : DragState -> Bool -> Model -> Model
handleDrag drag isEnd model =
    let
        canvas : CanvasProps
        canvas =
            model.project |> M.mapOrElse (.layout >> .canvas) CanvasProps.zero
    in
    if drag.id == Conf.ids.erd then
        if isEnd then
            model |> setCurrentLayout (setCanvas (moveCanvas drag))

        else
            model

    else if drag.id == Conf.ids.selectionBox then
        if isEnd then
            { model | selectionBox = Nothing }

        else
            drag
                |> buildSelectionArea model.screen canvas
                |> (\area ->
                        { model | selectionBox = Just area }
                            |> setCurrentLayout (setTables (List.map (\t -> { t | selected = Area.overlap area (t |> TableProps.area) })))
                   )

    else if isEnd then
        model
            |> setLayoutTables (moveTables drag canvas.zoom)
            |> setErd (setTableProps (moveTables2 drag canvas.zoom))

    else
        model


moveCanvas : DragState -> CanvasProps -> CanvasProps
moveCanvas drag canvas =
    { canvas | position = canvas.position |> move drag 1 }


moveTables : DragState -> ZoomLevel -> List TableProps -> List TableProps
moveTables drag zoom tables =
    let
        tableId : TableId
        tableId =
            TableId.fromHtmlId drag.id

        dragSelected : Bool
        dragSelected =
            tables |> L.findBy .id tableId |> M.mapOrElse .selected False
    in
    tables
        |> List.map
            (\p ->
                if tableId == p.id || (dragSelected && p.selected) then
                    { p | position = p.position |> move drag zoom }

                else
                    p
            )


moveTables2 : DragState -> ZoomLevel -> Dict TableId ErdTableProps -> Dict TableId ErdTableProps
moveTables2 drag zoom tables =
    let
        tableId : TableId
        tableId =
            TableId.fromHtmlId drag.id

        dragSelected : Bool
        dragSelected =
            tables |> Dict.get tableId |> M.mapOrElse .selected False
    in
    tables
        |> Dict.map
            (\id p ->
                if tableId == id || (dragSelected && p.selected) then
                    p |> setErdTablePropsPosition (p.position |> move drag zoom)

                else
                    p
            )


move : DragState -> ZoomLevel -> Position -> Position
move drag zoom position =
    position |> Position.add ((drag.last |> Position.sub drag.init) |> Position.div zoom)


buildSelectionArea : ScreenProps -> CanvasProps -> DragState -> Area
buildSelectionArea screen canvas dragState =
    Area.from dragState.init dragState.last
        |> Area.move (screen.position |> Position.add canvas.position |> Position.negate)
        |> Area.div canvas.zoom
