module PagesComponents.Organization_.Project_.Updates.Drag exposing (handleDrag, moveCanvas, moveInLayout)

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
import Models.Project.TableRow as TableRow exposing (TableRow)
import PagesComponents.Organization_.Project_.Models exposing (Model)
import PagesComponents.Organization_.Project_.Models.DragState exposing (DragState)
import PagesComponents.Organization_.Project_.Models.Erd as Erd
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty)
import Services.Lenses exposing (mapCanvas, mapErdM, mapMemos, mapPosition, mapProps, mapTableRows, mapTables, setSelected, setSelectionBox)
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
            ( model |> mapErdM (Erd.mapCurrentLayoutWithTime now (mapCanvas (moveCanvas drag))), Cmd.none )

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
                            |> mapErdM
                                (Erd.mapCurrentLayoutWithTime now
                                    (mapTables (List.map (mapProps (\p -> p |> setSelected (Area.overlapCanvas area { position = p.position |> Position.offGrid, size = p.size }))))
                                        >> mapTableRows (List.map (\r -> r |> setSelected (Area.overlapCanvas area { position = r.position |> Position.offGrid, size = r.size })))
                                        >> mapMemos (List.map (\m -> m |> setSelected (Area.overlapCanvas area { position = m.position |> Position.offGrid, size = m.size })))
                                    )
                                )
                   )
            , Cmd.none
            )

    else if isEnd && drag.init /= drag.last then
        model |> mapErdM (Erd.mapCurrentLayoutWithTime now (moveInLayout drag canvas.zoom)) |> setDirty

    else
        ( model, Cmd.none )


moveCanvas : DragState -> CanvasProps -> CanvasProps
moveCanvas drag canvas =
    canvas |> mapPosition (Position.moveDiagram (buildDelta drag 1))


moveInLayout : DragState -> ZoomLevel -> ErdLayout -> ErdLayout
moveInLayout drag zoom layout =
    let
        dragSelected : Bool
        dragSelected =
            (drag.id |> TableId.fromHtmlId |> Maybe.andThen (\id -> layout.tables |> List.find (\t -> t.id == id)) |> Maybe.mapOrElse (.props >> .selected) False)
                || (drag.id |> TableRow.fromHtmlId |> Maybe.andThen (\id -> layout.tableRows |> List.find (\r -> r.id == id)) |> Maybe.mapOrElse .selected False)
                || (drag.id |> MemoId.fromHtmlId |> Maybe.andThen (\id -> layout.memos |> List.find (\m -> m.id == id)) |> Maybe.mapOrElse .selected False)

        delta : Delta
        delta =
            buildDelta drag zoom
    in
    layout
        |> mapTables
            (List.map
                (\t ->
                    if drag.id == TableId.toHtmlId t.id || (dragSelected && t.props.selected) then
                        t |> mapProps (mapPosition (Position.moveGrid delta))

                    else
                        t
                )
            )
        |> mapTableRows
            (List.map
                (\r ->
                    if drag.id == TableRow.toHtmlId r.id || (dragSelected && r.selected) then
                        r |> mapPosition (Position.moveGrid delta)

                    else
                        r
                )
            )
        |> mapMemos
            (List.map
                (\m ->
                    if drag.id == MemoId.toHtmlId m.id || (dragSelected && m.selected) then
                        m |> mapPosition (Position.moveGrid delta)

                    else
                        m
                )
            )


buildDelta : DragState -> ZoomLevel -> Delta
buildDelta drag zoom =
    drag.last |> Position.diffViewport drag.init |> Delta.div zoom


buildSelectionArea : ErdProps -> CanvasProps -> DragState -> Area.Canvas
buildSelectionArea erdElem canvas dragState =
    Area.fromCanvas
        (dragState.init |> Position.viewportToCanvas erdElem.position canvas.position canvas.zoom)
        (dragState.last |> Position.viewportToCanvas erdElem.position canvas.position canvas.zoom)
