module PagesComponents.Organization_.Project_.Updates.Canvas exposing (applyAutoLayout, computeFit, fitCanvas, handleWheel, launchAutoLayout, performZoom, squashViewHistory, zoomCanvas)

import Conf
import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.Html.Events exposing (WheelEvent)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Area exposing (Area)
import Libs.Models.Delta as Delta exposing (Delta)
import Libs.Models.Position as Position
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Task as T
import Models.Area as Area
import Models.AutoLayout exposing (AutoLayoutMethod, DiagramEdge, DiagramNode)
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableRow as TableRow exposing (TableRow)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models exposing (Model, Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Organization_.Project_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.LinkLayout exposing (LinkLayout)
import PagesComponents.Organization_.Project_.Models.LinkLayoutId as LinkLayoutId exposing (LinkLayoutId)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId exposing (MemoId)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Ports
import Services.Lenses exposing (mapLinks, mapMemos, mapPosition, mapProps, mapTableRows, mapTables, setCanvas, setLayoutOnLoad, setPosition)
import Services.Toasts as Toasts
import Time


handleWheel : WheelEvent -> ErdProps -> CanvasProps -> ( CanvasProps, Extra Msg )
handleWheel event erdElem canvas =
    if event.ctrl then
        canvas |> performZoom erdElem (-event.delta.dy * Conf.canvas.zoom.speed * canvas.zoom) event.clientPos

    else
        { canvas | position = canvas.position |> Position.moveDiagram (event.delta |> Delta.negate |> Delta.adjust canvas.zoom) }
            |> (\new -> ( new, Extra.history ( SetView_ canvas, SetView_ new ) ))


zoomCanvas : Float -> ErdProps -> CanvasProps -> ( CanvasProps, Extra Msg )
zoomCanvas delta erdElem canvas =
    canvas |> performZoom erdElem delta (erdElem |> Area.centerViewport)


fitCanvas : ErdProps -> Erd -> ( Erd, Extra Msg )
fitCanvas erdElem erd =
    (erd |> Erd.currentLayout |> objectsToFit)
        |> Maybe.map (\( ( ( tables, rows ), ( memos, links ) ), _ ) -> (tables |> List.map (.props >> Area.offGrid)) ++ (rows |> List.map Area.offGrid) ++ (memos |> List.map Area.offGrid) ++ (links |> List.map Area.offGrid))
        |> Maybe.map (\areas -> erd |> setLayoutOnLoad "" |> Erd.mapCurrentLayoutT (fitCanvasAlgo erdElem areas) |> Extra.defaultT)
        |> Maybe.withDefault ( erd, "No table to fit into the canvas" |> Toasts.create "warning" |> Toast |> Extra.msg )


fitCanvasAlgo : ErdProps -> List Area.Canvas -> ErdLayout -> ( ErdLayout, Extra Msg )
fitCanvasAlgo erdElem areas layout =
    -- WARNING: the computation is good but the diagram can change due to table header size change
    -- (see headerTextSize in frontend/src/Components/Organisms/Table.elm:177)
    -- if you look to fix it, make sure to disable it before testing!
    (areas |> Area.mergeCanvas)
        |> Maybe.map
            (\contentArea ->
                let
                    ( newZoom, centerOffset ) =
                        computeFit (layout.canvas |> CanvasProps.viewport erdElem) Conf.constants.canvasMargins contentArea layout.canvas.zoom

                    canvas : CanvasProps
                    canvas =
                        { position = Position.zeroDiagram, zoom = newZoom }
                in
                ( layout
                    |> setCanvas canvas
                    |> mapTables (List.map (mapProps (mapPosition (Position.moveGrid centerOffset))))
                    |> mapTableRows (List.map (mapPosition (Position.moveGrid centerOffset)))
                    |> mapMemos (List.map (mapPosition (Position.moveGrid centerOffset)))
                    |> mapLinks (List.map (mapPosition (Position.moveGrid centerOffset)))
                , Extra.history ( SetView_ (layout.canvas |> mapPosition (Position.moveDiagram (Delta.negate centerOffset))), SetView_ canvas )
                )
            )
        |> Maybe.withDefault ( layout, Extra.none )


launchAutoLayout : AutoLayoutMethod -> ErdProps -> Erd -> Cmd Msg
launchAutoLayout method erdElem erd =
    -- TODO: toggle this on show all tables if layout was empty before, see frontend/src/PagesComponents/Organization_/Project_/Updates/Table.elm:128#showAllTables
    (erd |> Erd.currentLayout |> objectsToFit)
        |> Maybe.map
            (\( ( ( tables, rows ), ( memos, links ) ), full ) ->
                let
                    viewport : Area
                    viewport =
                        if full then
                            erd |> Erd.viewport erdElem |> Area.extractCanvas

                        else
                            ((tables |> List.map (.props >> Area.offGrid)) ++ (rows |> List.map Area.offGrid) ++ (memos |> List.map Area.offGrid) ++ (links |> List.map Area.offGrid)) |> Area.mergeCanvas |> Maybe.withDefault Area.zeroCanvas |> Area.extractCanvas

                    nodes : List DiagramNode
                    nodes =
                        (tables |> List.map (\t -> { id = "table/" ++ TableId.toString t.id, size = t.props.size |> Size.extractCanvas, position = t.props.position |> Position.extractGrid }))
                            ++ (rows |> List.map (\r -> { id = "row/" ++ TableRow.toString r.id, size = r.size |> Size.extractCanvas, position = r.position |> Position.extractGrid }))
                            ++ (memos |> List.map (\m -> { id = "memo/" ++ MemoId.toString m.id, size = m.size |> Size.extractCanvas, position = m.position |> Position.extractGrid }))
                            ++ (links |> List.map (\m -> { id = "link/" ++ LinkLayoutId.toString m.id, size = m.size |> Size.extractCanvas, position = m.position |> Position.extractGrid }))

                    tablesById : Dict TableId ErdTableLayout
                    tablesById =
                        tables |> List.indexBy .id

                    edges : List DiagramEdge
                    edges =
                        erd.relations
                            |> List.filter (\r -> isShown tablesById r.src && isShown tablesById r.ref)
                            |> List.map (\r -> { src = "table/" ++ TableId.toString r.src.table, ref = "table/" ++ TableId.toString r.ref.table })
                in
                Ports.getAutoLayout method viewport nodes edges
            )
        |> Maybe.withDefault ("Nothing to arrange in the canvas" |> Toasts.create "warning" |> Toast |> T.send)


isShown : Dict TableId ErdTableLayout -> ErdColumnRef -> Bool
isShown tablesById ref =
    tablesById |> Dict.get ref.table |> Maybe.any (.columns >> ErdColumnProps.member ref.column)


applyAutoLayout : Time.Posix -> ErdProps -> List DiagramNode -> Erd -> ( Erd, Extra Msg )
applyAutoLayout now erdElem nodes erd =
    (erd |> Erd.currentLayout |> objectsToFit)
        |> Maybe.map
            (\( ( ( tables, rows ), ( memos, links ) ), full ) ->
                erd
                    |> setLayoutOnLoad ""
                    |> Erd.mapCurrentLayoutTWithTime now
                        (\layout ->
                            let
                                currentArea : Area.Canvas
                                currentArea =
                                    ((tables |> List.map (.props >> Area.offGrid)) ++ (rows |> List.map Area.offGrid) ++ (memos |> List.map Area.offGrid) ++ (links |> List.map Area.offGrid)) |> Area.mergeCanvas |> Maybe.withDefault Area.zeroCanvas

                                computedArea : Area.Canvas
                                computedArea =
                                    nodes |> List.map Area.canvas |> Area.mergeCanvas |> Maybe.withDefault Area.zeroCanvas

                                delta : Delta
                                delta =
                                    currentArea.position |> Position.diffCanvas computedArea.position

                                nodesByKind : Dict String (List { id : String, pos : Position.Grid })
                                nodesByKind =
                                    nodes |> List.groupBy (\n -> n.id |> String.split "/" |> List.headOr "") |> Dict.mapValues (List.map (\n -> { id = n.id |> String.split "/" |> List.drop 1 |> String.join "/", pos = n.position |> Position.move delta |> Position.grid }))

                                tablePositions : Dict TableId Position.Grid
                                tablePositions =
                                    nodesByKind |> Dict.getOrElse "table" [] |> List.filterMap (\n -> n.id |> TableId.fromString |> Maybe.map (\id -> { id = id, pos = n.pos })) |> List.indexBy .id |> Dict.mapValues .pos

                                rowNodes : Dict TableRow.Id Position.Grid
                                rowNodes =
                                    nodesByKind |> Dict.getOrElse "row" [] |> List.filterMap (\n -> n.id |> TableRow.fromString |> Maybe.map (\id -> { id = id, pos = n.pos })) |> List.indexBy .id |> Dict.mapValues .pos

                                memoNodes : Dict MemoId Position.Grid
                                memoNodes =
                                    nodesByKind |> Dict.getOrElse "memo" [] |> List.filterMap (\n -> n.id |> MemoId.fromString |> Maybe.map (\id -> { id = id, pos = n.pos })) |> List.indexBy .id |> Dict.mapValues .pos

                                linkNodes : Dict LinkLayoutId Position.Grid
                                linkNodes =
                                    nodesByKind |> Dict.getOrElse "link" [] |> List.filterMap (\n -> n.id |> LinkLayoutId.fromString |> Maybe.map (\id -> { id = id, pos = n.pos })) |> List.indexBy .id |> Dict.mapValues .pos
                            in
                            layout
                                |> mapTables (List.map (\t -> tablePositions |> Dict.get t.id |> Maybe.mapOrElse (\pos -> t |> mapProps (setPosition pos)) t))
                                |> mapTableRows (List.map (\r -> rowNodes |> Dict.get r.id |> Maybe.mapOrElse (\p -> r |> setPosition p) r))
                                |> mapMemos (List.map (\m -> memoNodes |> Dict.get m.id |> Maybe.mapOrElse (\p -> m |> setPosition p) m))
                                |> mapLinks (List.map (\l -> linkNodes |> Dict.get l.id |> Maybe.mapOrElse (\p -> l |> setPosition p) l))
                                |> (\newLayout ->
                                        if full then
                                            fitCanvasAlgo erdElem [ computedArea |> mapPosition (Position.moveCanvas delta) ] newLayout

                                        else
                                            ( newLayout, Extra.none )
                                   )
                                |> (\( newLayout, extra ) -> ( newLayout, extra |> Extra.setHistory ( SetLayout_ layout, SetLayout_ newLayout ) ))
                        )
                    |> Extra.defaultT
            )
        |> Maybe.withDefault ( erd, "No table to arrange in the canvas" |> Toasts.create "warning" |> Toast |> Extra.msg )


objectsToFit : ErdLayout -> Maybe ( ( ( List ErdTableLayout, List TableRow ), ( List Memo, List LinkLayout ) ), Bool )
objectsToFit layout =
    let
        selectedTables : List ErdTableLayout
        selectedTables =
            layout.tables |> List.filter (.props >> .selected)

        selectedRows : List TableRow
        selectedRows =
            layout.tableRows |> List.filter .selected

        selectedMemos : List Memo
        selectedMemos =
            layout.memos |> List.filter .selected

        selectedLinks : List LinkLayout
        selectedLinks =
            layout.links |> List.filter .selected
    in
    if selectedTables /= [] || selectedRows /= [] || selectedMemos /= [] || selectedLinks /= [] then
        Just ( ( ( selectedTables, selectedRows ), ( selectedMemos, selectedLinks ) ), False )

    else if layout.tables /= [] || layout.tableRows /= [] || layout.memos /= [] || layout.memos /= [] then
        Just ( ( ( layout.tables, layout.tableRows ), ( layout.memos, layout.links ) ), True )

    else
        Nothing


performZoom : ErdProps -> Float -> Position.Viewport -> CanvasProps -> ( CanvasProps, Extra Msg )
performZoom erdElem delta target canvas =
    -- to zoom on target (center or cursor), works only if origin is top left (CSS: "transform-origin: top left;")
    let
        newZoom : ZoomLevel
        newZoom =
            (canvas.zoom + delta) |> clamp Conf.canvas.zoom.min Conf.canvas.zoom.max

        targetDelta : Delta
        targetDelta =
            target
                |> Position.viewportToCanvas erdElem.position canvas.position canvas.zoom
                |> Position.canvasToViewport erdElem.position canvas.position newZoom
                |> Position.diffViewport target
    in
    { position = canvas.position |> Position.moveDiagram (targetDelta |> Delta.negate) |> Position.roundDiagram
    , zoom = newZoom
    }
        |> (\newCanvas -> ( newCanvas, Extra.history ( SetView_ canvas, SetView_ newCanvas ) ))


computeFit : Area.Canvas -> Float -> Area.Canvas -> ZoomLevel -> ( ZoomLevel, Delta )
computeFit erdViewport padding content zoom =
    let
        newZoom : ZoomLevel
        newZoom =
            computeZoom erdViewport padding content zoom

        growFactor : Float
        growFactor =
            newZoom / zoom

        newViewport : Area.Canvas
        newViewport =
            erdViewport |> Area.divCanvas growFactor

        newViewportCenter : Position.Canvas
        newViewportCenter =
            newViewport |> Area.centerCanvas |> Position.moveCanvas (Position.zeroCanvas |> Position.diffCanvas newViewport.position)

        newContentCenter : Position.Canvas
        newContentCenter =
            content |> Area.centerCanvas

        offset : Delta
        offset =
            newViewportCenter |> Position.diffCanvas newContentCenter
    in
    ( newZoom, offset )


computeZoom : Area.Canvas -> Float -> Area.Canvas -> Float -> ZoomLevel
computeZoom erdViewport padding contentArea zoom =
    let
        viewportSize : Size.Canvas
        viewportSize =
            erdViewport.size |> Size.subCanvas (2 * padding / zoom)

        grow : Delta
        grow =
            viewportSize |> Size.ratioCanvas contentArea.size

        newZoom : ZoomLevel
        newZoom =
            (zoom * min grow.dx grow.dy) |> clamp Conf.canvas.zoom.min 1
    in
    newZoom


squashViewHistory : ( Model, Extra Msg ) -> ( Model, Extra Msg )
squashViewHistory ( model, e ) =
    case ( model.history, e.history ) of
        ( ( SetView_ first, SetView_ _ ) :: rest, [ ( SetView_ _, SetView_ last ) ] ) ->
            ( { model | history = rest }, e |> Extra.setHistory ( SetView_ first, SetView_ last ) )

        _ ->
            ( model, e )
