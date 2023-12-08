module PagesComponents.Organization_.Project_.Updates.Drag exposing (handleDrag, moveCanvas, moveInLayout)

import Conf
import Dict exposing (Dict)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Delta as Delta exposing (Delta)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Area as Area
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableRow as TableRow exposing (TableRow)
import PagesComponents.Organization_.Project_.Models as Msg exposing (Model, Msg, buildHistory)
import PagesComponents.Organization_.Project_.Models.DragState exposing (DragState)
import PagesComponents.Organization_.Project_.Models.Erd as Erd
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId exposing (MemoId)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (addHistoryT, setDirty)
import Services.Lenses exposing (mapCanvasT, mapErdM, mapErdMTM, mapMemos, mapProps, mapTableRows, mapTables, setPosition, setSelected, setSelectionBox)
import Time


handleDrag : String -> Time.Posix -> DragState -> Bool -> Model -> ( Model, Cmd Msg )
handleDrag doCmd now drag isEnd model =
    let
        canvas : CanvasProps
        canvas =
            model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .canvas) CanvasProps.empty
    in
    if drag.id == Conf.ids.erd then
        if isEnd && drag.init /= drag.last then
            ( model |> mapErdMTM (Erd.mapCurrentLayoutTMWithTime now (mapCanvasT (moveCanvas drag))) |> addHistoryT doCmd, Cmd.none )

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
        model |> mapErdMTM (Erd.mapCurrentLayoutTMWithTime now (moveInLayout drag canvas.zoom)) |> addHistoryT doCmd |> setDirty

    else
        ( model, Cmd.none )


moveCanvas : DragState -> CanvasProps -> ( CanvasProps, Maybe ( Msg, Msg ) )
moveCanvas drag canvas =
    (canvas.position |> Position.moveDiagram (buildDelta drag 1))
        |> (\newPos -> ( canvas |> setPosition newPos, Just ( Msg.CanvasPosition canvas.position, Msg.CanvasPosition newPos ) ))


moveInLayout : DragState -> ZoomLevel -> ErdLayout -> ( ErdLayout, Maybe ( Msg, Msg ) )
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

        shouldMove : id -> (id -> HtmlId) -> { p | selected : Bool, position : Position.Grid } -> (id -> Position.Grid -> Msg) -> Maybe ( id, ( Position.Grid, ( Msg, Msg ) ) )
        shouldMove id toHtmlId props move =
            if drag.id == toHtmlId id || (dragSelected && props.selected) then
                props.position |> Position.moveGrid delta |> (\newPos -> Just ( id, ( newPos, ( move id props.position, move id newPos ) ) ))

            else
                Nothing

        moveTables : Dict TableId ( Position.Grid, ( Msg, Msg ) )
        moveTables =
            layout.tables |> List.filterMap (\t -> shouldMove t.id TableId.toHtmlId t.props Msg.TablePosition) |> Dict.fromList

        moveTableRows : Dict TableRow.Id ( Position.Grid, ( Msg, Msg ) )
        moveTableRows =
            layout.tableRows |> List.filterMap (\r -> shouldMove r.id TableRow.toHtmlId r Msg.TableRowPosition) |> Dict.fromList

        moveMemos : Dict MemoId ( Position.Grid, ( Msg, Msg ) )
        moveMemos =
            layout.memos |> List.filterMap (\m -> shouldMove m.id MemoId.toHtmlId m Msg.MemoPosition) |> Dict.fromList
    in
    ( layout
        |> mapTables (List.map (\t -> moveTables |> Dict.get t.id |> Maybe.mapOrElse (\( pos, _ ) -> t |> mapProps (setPosition pos)) t))
        |> mapTableRows (List.map (\r -> moveTableRows |> Dict.get r.id |> Maybe.mapOrElse (\( pos, _ ) -> r |> setPosition pos) r))
        |> mapMemos (List.map (\m -> moveMemos |> Dict.get m.id |> Maybe.mapOrElse (\( pos, _ ) -> m |> setPosition pos) m))
    , (Dict.values moveTables ++ Dict.values moveTableRows ++ Dict.values moveMemos) |> List.map Tuple.second |> buildHistory
    )


buildDelta : DragState -> ZoomLevel -> Delta
buildDelta drag zoom =
    drag.last |> Position.diffViewport drag.init |> Delta.div zoom


buildSelectionArea : ErdProps -> CanvasProps -> DragState -> Area.Canvas
buildSelectionArea erdElem canvas dragState =
    Area.fromCanvas
        (dragState.init |> Position.viewportToCanvas erdElem.position canvas.position canvas.zoom)
        (dragState.last |> Position.viewportToCanvas erdElem.position canvas.position canvas.zoom)
