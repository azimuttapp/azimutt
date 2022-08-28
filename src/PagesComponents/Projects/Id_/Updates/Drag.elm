module PagesComponents.Projects.Id_.Updates.Drag exposing (handleDrag, moveCanvas, moveTables)

import Conf
import Libs.Delta as Delta exposing (Delta)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Area as Area
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId as TableId exposing (TableId)
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
                |> buildSelectionArea model.erdElem canvas
                |> (\area ->
                        model
                            |> setSelectionBox (Just area)
                            |> mapErdM (Erd.mapCurrentLayout now (mapTables (List.map (mapProps (\p -> p |> setSelected (Area.overlapInCanvas area { position = p.position |> Position.offGrid, size = p.size }))))))
                   )

    else if isEnd then
        model |> mapErdM (Erd.mapCurrentLayout now (mapTables (moveTables drag canvas.zoom)))

    else
        model


moveCanvas : DragState -> CanvasProps -> CanvasProps
moveCanvas drag canvas =
    canvas |> mapPosition (Position.moveCanvas (buildDelta drag 1))


moveTables : DragState -> ZoomLevel -> List ErdTableLayout -> List ErdTableLayout
moveTables drag zoom tables =
    let
        tableId : Maybe TableId
        tableId =
            TableId.fromHtmlId drag.id

        dragSelected : Bool
        dragSelected =
            tableId |> Maybe.mapOrElse (\id -> tables |> List.findBy .id id |> Maybe.mapOrElse (.props >> .selected) False) False
    in
    tables
        |> List.map
            (\t ->
                if Just t.id == tableId || (dragSelected && t.props.selected) then
                    t |> mapProps (mapPosition (Position.moveGrid (buildDelta drag zoom)))

                else
                    t
            )


buildDelta : DragState -> ZoomLevel -> Delta
buildDelta drag zoom =
    drag.last |> Position.diffViewport drag.init |> Delta.div zoom


buildSelectionArea : ErdProps -> CanvasProps -> DragState -> Area.InCanvas
buildSelectionArea erdElem canvas dragState =
    Area.fromInCanvas
        (dragState.init |> Position.viewportToInCanvas erdElem.position canvas.position canvas.zoom)
        (dragState.last |> Position.viewportToInCanvas erdElem.position canvas.position canvas.zoom)
