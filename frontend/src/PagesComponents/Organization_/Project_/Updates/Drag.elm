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
import PagesComponents.Organization_.Project_.Models as Msg exposing (Model, Msg(..))
import PagesComponents.Organization_.Project_.Models.DragState exposing (DragState)
import PagesComponents.Organization_.Project_.Models.Erd as Erd
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId exposing (MemoId)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirtyM)
import Services.Lenses exposing (mapCanvasT, mapErdM, mapErdMTM, mapMemos, mapProps, mapSelectionBox, mapTableRows, mapTables, setArea, setPosition, setSelectionBox)
import Time


handleDrag : Time.Posix -> DragState -> Bool -> Bool -> Model -> ( Model, Extra Msg )
handleDrag now drag isEnd cancel model =
    let
        canvas : CanvasProps
        canvas =
            model.erd |> Maybe.mapOrElse (Erd.currentLayout >> .canvas) CanvasProps.empty
    in
    if drag.id == Conf.ids.erd then
        if isEnd && drag.init /= drag.last then
            model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (mapCanvasT (moveCanvas drag))) |> Extra.defaultT

        else
            ( model, Extra.none )

    else if drag.id == Conf.ids.selectionBox then
        let
            currentlySelected : List HtmlId
            currentlySelected =
                model.erd |> Maybe.mapOrElse (Erd.currentLayout >> ErdLayout.getSelected) []
        in
        if isEnd then
            let
                previouslySelected : List HtmlId
                previouslySelected =
                    model.selectionBox |> Maybe.mapOrElse .previouslySelected []
            in
            if cancel then
                ( model |> setSelectionBox Nothing |> mapErdM (Erd.mapCurrentLayout (ErdLayout.setSelected previouslySelected)), Extra.none )

            else
                ( model |> setSelectionBox Nothing
                , if previouslySelected /= currentlySelected then
                    Extra.history ( SelectItems_ previouslySelected, SelectItems_ currentlySelected )

                  else
                    Extra.none
                )

        else
            ( drag
                |> buildSelectionArea model.erdElem canvas
                |> (\area ->
                        model
                            |> mapSelectionBox (Maybe.map (setArea area) >> Maybe.withDefault { area = area, previouslySelected = currentlySelected } >> Just)
                            |> mapErdM (Erd.mapCurrentLayoutWithTime now (ErdLayout.mapSelected (\i _ -> Area.overlapCanvas area { position = i.position |> Position.offGrid, size = i.size })))
                   )
            , Extra.none
            )

    else if isEnd && drag.init /= drag.last then
        model |> mapErdMTM (Erd.mapCurrentLayoutTWithTime now (moveInLayout drag canvas.zoom)) |> setDirtyM

    else
        ( model, Extra.none )


moveCanvas : DragState -> CanvasProps -> ( CanvasProps, Extra Msg )
moveCanvas drag canvas =
    (canvas.position |> Position.moveDiagram (buildDelta drag 1))
        |> (\newPos -> ( canvas |> setPosition newPos, Extra.history ( Msg.CanvasPosition_ canvas.position, Msg.CanvasPosition_ newPos ) ))


moveInLayout : DragState -> ZoomLevel -> ErdLayout -> ( ErdLayout, Extra Msg )
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
            layout.tableRows |> List.filterMap (\r -> shouldMove r.id TableRow.toHtmlId r Msg.TableRowPosition_) |> Dict.fromList

        moveMemos : Dict MemoId ( Position.Grid, ( Msg, Msg ) )
        moveMemos =
            layout.memos |> List.filterMap (\m -> shouldMove m.id MemoId.toHtmlId m Msg.MemoPosition_) |> Dict.fromList
    in
    ( layout
        |> mapTables (List.map (\t -> moveTables |> Dict.get t.id |> Maybe.mapOrElse (\( pos, _ ) -> t |> mapProps (setPosition pos)) t))
        |> mapTableRows (List.map (\r -> moveTableRows |> Dict.get r.id |> Maybe.mapOrElse (\( pos, _ ) -> r |> setPosition pos) r))
        |> mapMemos (List.map (\m -> moveMemos |> Dict.get m.id |> Maybe.mapOrElse (\( pos, _ ) -> m |> setPosition pos) m))
    , (Dict.values moveTables ++ Dict.values moveTableRows ++ Dict.values moveMemos) |> List.map Tuple.second |> Extra.historyL
    )


buildDelta : DragState -> ZoomLevel -> Delta
buildDelta drag zoom =
    drag.last |> Position.diffViewport drag.init |> Delta.div zoom


buildSelectionArea : ErdProps -> CanvasProps -> DragState -> Area.Canvas
buildSelectionArea erdElem canvas dragState =
    Area.fromCanvas
        (dragState.init |> Position.viewportToCanvas erdElem.position canvas.position canvas.zoom)
        (dragState.last |> Position.viewportToCanvas erdElem.position canvas.position canvas.zoom)
