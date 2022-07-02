module PagesComponents.Projects.Id_.Updates.Drag exposing (handleDrag, moveCanvas, moveTables)

import Conf
import Libs.Area as Area exposing (Area)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ScreenProps exposing (ScreenProps)
import PagesComponents.Projects.Id_.Models exposing (Model)
import PagesComponents.Projects.Id_.Models.DragState exposing (DragState)
import PagesComponents.Projects.Id_.Models.Erd as Erd
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)
import Services.Lenses exposing (mapCanvas, mapErdM, mapPosition, mapProps, mapTables, setSelected, setSelectionBox)
import Time


handleDrag : Time.Posix -> DragState -> Bool -> Model -> Model
handleDrag now drag isEnd model =
    let
        canvas : CanvasProps
        canvas =
            model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .canvas) CanvasProps.empty
    in
    if drag.id == Conf.ids.erd then
        if isEnd then
            model |> mapErdM (Erd.mapCurrentLayout now (mapCanvas (moveCanvas drag)))

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
                            |> mapErdM (Erd.mapCurrentLayout now (mapTables (List.map (mapProps (\p -> p |> setSelected (Area.overlap area p))))))
                   )

    else if isEnd then
        model |> mapErdM (Erd.mapCurrentLayout now (mapTables (moveTables drag canvas.zoom)))

    else
        model


moveCanvas : DragState -> CanvasProps -> CanvasProps
moveCanvas drag canvas =
    canvas |> mapPosition (move drag 1)


moveTables : DragState -> ZoomLevel -> List ErdTableLayout -> List ErdTableLayout
moveTables drag zoom tables =
    let
        tableId : TableId
        tableId =
            TableId.fromHtmlId drag.id

        dragSelected : Bool
        dragSelected =
            tables |> List.findBy .id tableId |> Maybe.mapOrElse (.props >> .selected) False
    in
    tables
        |> List.map
            (\t ->
                if tableId == t.id || (dragSelected && t.props.selected) then
                    t |> mapProps (mapPosition (move drag zoom >> Position.stepBy Conf.canvas.grid))

                else
                    t
            )


move : DragState -> ZoomLevel -> Position -> Position
move drag zoom position =
    position |> Position.add ((drag.last |> Position.sub drag.init) |> Position.div zoom)


buildSelectionArea : ScreenProps -> CanvasProps -> DragState -> Area
buildSelectionArea screen canvas dragState =
    Area.from dragState.init dragState.last
        |> Area.move (screen.position |> Position.add { left = 0, top = Conf.ui.navbarHeight } |> Position.add canvas.position |> Position.negate)
        |> Area.div canvas.zoom
