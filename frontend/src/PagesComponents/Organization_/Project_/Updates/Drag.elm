module PagesComponents.Organization_.Project_.Updates.Drag exposing (handleDrag, moveCanvas, moveMemos, moveTables)

import Conf
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Delta as Delta exposing (Delta)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Area as Area
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models exposing (Model)
import PagesComponents.Organization_.Project_.Models.DragState exposing (DragState)
import PagesComponents.Organization_.Project_.Models.Erd as Erd
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Memo as Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty)
import Services.Lenses exposing (mapCanvas, mapErdM, mapMemos, mapPosition, mapProps, mapTables, setSelected, setSelectionBox)
import Time


handleDrag : Time.Posix -> DragState -> Bool -> Model -> ( Model, Cmd msg )
handleDrag now drag isEnd model =
    let
        canvas : CanvasProps
        canvas =
            model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .canvas) CanvasProps.empty
    in
    if drag.id == Conf.ids.erd then
        if isEnd && drag.init /= drag.last then
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapCanvas (moveCanvas drag))) |> setDirty

        else
            ( model, Cmd.none )

    else if drag.id == Conf.ids.selectionBox then
        if isEnd then
            ( model |> setSelectionBox Nothing, Cmd.none )

        else
            ( drag
                |> buildSelectionArea model.erdElem canvas
                |> (\area ->
                        model
                            |> setSelectionBox (Just area)
                            |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (List.map (mapProps (\p -> p |> setSelected (Area.overlapCanvas area { position = p.position |> Position.offGrid, size = p.size }))))))
                   )
            , Cmd.none
            )

    else if isEnd && drag.init /= drag.last then
        if drag.id |> String.startsWith Memo.htmlIdPrefix then
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapMemos (moveMemos drag canvas.zoom))) |> setDirty

        else
            model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapTables (moveTables drag canvas.zoom))) |> setDirty

    else
        ( model, Cmd.none )


moveCanvas : DragState -> CanvasProps -> CanvasProps
moveCanvas drag canvas =
    canvas |> mapPosition (Position.moveDiagram (buildDelta drag 1))


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


moveMemos : DragState -> ZoomLevel -> List Memo -> List Memo
moveMemos drag zoom memos =
    memos
        |> List.map
            (\m ->
                if drag.id == Memo.htmlId m.id then
                    m |> mapPosition (Position.moveGrid (buildDelta drag zoom))

                else
                    m
            )


buildDelta : DragState -> ZoomLevel -> Delta
buildDelta drag zoom =
    drag.last |> Position.diffViewport drag.init |> Delta.div zoom


buildSelectionArea : ErdProps -> CanvasProps -> DragState -> Area.Canvas
buildSelectionArea erdElem canvas dragState =
    Area.fromCanvas
        (dragState.init |> Position.viewportToCanvas erdElem.position canvas.position canvas.zoom)
        (dragState.last |> Position.viewportToCanvas erdElem.position canvas.position canvas.zoom)
