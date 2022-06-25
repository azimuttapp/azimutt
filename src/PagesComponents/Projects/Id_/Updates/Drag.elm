module PagesComponents.Projects.Id_.Updates.Drag exposing (handleDrag, moveCanvas, moveTables)

import Conf
import Dict exposing (Dict)
import Libs.Area as Area exposing (Area)
import Libs.Maybe as Maybe
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ScreenProps exposing (ScreenProps)
import PagesComponents.Projects.Id_.Models exposing (Model)
import PagesComponents.Projects.Id_.Models.DragState exposing (DragState)
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import Services.Lenses exposing (mapCanvas, mapErdM, mapPosition, mapTableProps, setSelectionBox)


handleDrag : DragState -> Bool -> Model -> Model
handleDrag drag isEnd model =
    let
        canvas : CanvasProps
        canvas =
            model.erd |> Maybe.mapOrElse .canvas CanvasProps.zero
    in
    if drag.id == Conf.ids.erd then
        if isEnd then
            model |> mapErdM (mapCanvas (moveCanvas drag))

        else
            model

    else if drag.id == Conf.ids.selectionBox then
        if isEnd then
            model |> setSelectionBox Nothing

        else
            drag
                |> buildSelectionArea model.screen canvas
                |> (\area ->
                        model
                            |> setSelectionBox (Just area)
                            |> mapErdM (mapTableProps (Dict.map (\_ p -> p |> ErdTableProps.setSelected (Area.overlap area (p |> ErdTableProps.area)))))
                   )

    else if isEnd then
        model |> mapErdM (mapTableProps (moveTables drag canvas.zoom))

    else
        model


moveCanvas : DragState -> CanvasProps -> CanvasProps
moveCanvas drag canvas =
    canvas |> mapPosition (move drag 1)


moveTables : DragState -> ZoomLevel -> Dict TableId ErdTableProps -> Dict TableId ErdTableProps
moveTables drag zoom tables =
    let
        tableId : TableId
        tableId =
            TableId.fromHtmlId drag.id

        dragSelected : Bool
        dragSelected =
            tables |> Dict.get tableId |> Maybe.mapOrElse .selected False
    in
    tables
        |> Dict.map
            (\id p ->
                if tableId == id || (dragSelected && p.selected) then
                    p |> ErdTableProps.setPosition (p.position |> move drag zoom)

                else
                    p
            )


move : DragState -> ZoomLevel -> Position -> Position
move drag zoom position =
    position |> Position.add ((drag.last |> Position.sub drag.init) |> Position.div zoom)


buildSelectionArea : ScreenProps -> CanvasProps -> DragState -> Area
buildSelectionArea screen canvas dragState =
    Area.from dragState.init dragState.last
        |> Area.move (screen.position |> Position.add { left = 0, top = Conf.ui.navbarHeight } |> Position.add canvas.position |> Position.negate)
        |> Area.div canvas.zoom
