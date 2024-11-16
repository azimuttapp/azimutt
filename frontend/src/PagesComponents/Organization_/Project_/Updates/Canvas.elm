module PagesComponents.Organization_.Project_.Updates.Canvas exposing (applyAutoLayout, computeFit, fitCanvas, handleWheel, launchAutoLayout, performZoom, squashViewHistory, zoomCanvas)

import Conf
import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.Html.Events exposing (WheelEvent)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Area exposing (Area)
import Libs.Models.Delta as Delta exposing (Delta)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Tuple3 as Tuple3
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
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout as ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId exposing (MemoId)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Ports
import Services.Lenses exposing (mapMemos, mapPosition, mapProps, mapTableRows, mapTables, setCanvas, setLayoutOnLoad, setPosition)
import Services.Toasts as Toasts
import Set exposing (Set)
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
        |> Maybe.map (\( tables, ( rows, memos, groups ) ) -> erd |> setLayoutOnLoad "" |> Erd.mapCurrentLayoutT (fitCanvasAlgo erdElem tables rows memos groups) |> Extra.defaultT)
        |> Maybe.withDefault ( erd, "No table to fit into the canvas" |> Toasts.create "warning" |> Toast |> Extra.msg )


fitCanvasAlgo : ErdProps -> List TableId -> List TableRow.Id -> List MemoId -> List Area.Canvas -> ErdLayout -> ( ErdLayout, Extra Msg )
fitCanvasAlgo erdElem tables rows memos groups layout =
    -- WARNING: the computation looks good but the diagram changes on resize due to table header size change
    -- (see headerTextSize in frontend/src/Components/Organisms/Table.elm:177)
    -- if you look to fix it, make sure to disable it before testing!
    ((layout.tables |> List.filterInBy .id tables |> List.map (.props >> Area.offGrid))
        ++ (layout.tableRows |> List.filterInBy .id rows |> List.map Area.offGrid)
        ++ (layout.memos |> List.filterInBy .id memos |> List.map Area.offGrid)
        ++ groups
    )
        |> Area.mergeCanvas
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
                , Extra.history ( SetView_ (layout.canvas |> mapPosition (Position.moveDiagram (Delta.negate centerOffset))), SetView_ canvas )
                )
            )
        |> Maybe.withDefault ( layout, Extra.none )


launchAutoLayout : AutoLayoutMethod -> ErdProps -> Erd -> ( Erd, Extra Msg )
launchAutoLayout method erdElem erd =
    -- TODO: toggle this on show all tables if layout was empty before, see frontend/src/PagesComponents/Organization_/Project_/Updates/Table.elm:106#showAllTables
    (erd |> Erd.currentLayout |> objectsToFit)
        |> Maybe.map
            (\( tables, ( rows, memos, _ ) ) ->
                let
                    viewport : Area
                    viewport =
                        erd |> Erd.viewport erdElem |> Area.extractCanvas

                    layout : ErdLayout
                    layout =
                        erd |> Erd.currentLayout

                    nodes : List DiagramNode
                    nodes =
                        (layout.tables |> List.filterInBy .id tables |> List.map (\t -> { id = "table/" ++ TableId.toString t.id, size = t.props.size |> Size.extractCanvas, pos = t.props.position |> Position.extractGrid }))
                            ++ (layout.tableRows |> List.filterInBy .id rows |> List.map (\r -> { id = "row/" ++ TableRow.toString r.id, size = r.size |> Size.extractCanvas, pos = r.position |> Position.extractGrid }))
                            ++ (layout.memos |> List.filterInBy .id memos |> List.map (\m -> { id = "memo/" ++ MemoId.toString m.id, size = m.size |> Size.extractCanvas, pos = m.position |> Position.extractGrid }))

                    ids : Set String
                    ids =
                        nodes |> List.map .id |> Set.fromList

                    edges : List DiagramEdge
                    edges =
                        (layout.tables |> List.filterInBy .id tables)
                            |> List.concatMap (\t -> t.relatedTables |> Dict.filter (\_ -> .shown) |> Dict.keys |> List.map (\id -> { src = "table/" ++ TableId.toString t.id, ref = "table/" ++ TableId.toString id }) |> List.filter (\r -> ids |> Set.member r.ref))
                in
                ( erd, Ports.getAutoLayout method viewport nodes edges |> Extra.cmd )
            )
        |> Maybe.withDefault ( erd, "No table to arrange in the canvas" |> Toasts.create "warning" |> Toast |> Extra.msg )


applyAutoLayout : Time.Posix -> ErdProps -> List DiagramNode -> Erd -> ( Erd, Extra Msg )
applyAutoLayout now erdElem nodes erd =
    (erd |> Erd.currentLayout |> objectsToFit)
        |> Maybe.map
            (\( tables, ( rows, memos, groups ) ) ->
                erd
                    |> setLayoutOnLoad ""
                    |> Erd.mapCurrentLayoutTWithTime now
                        (\layout ->
                            let
                                nodesByKind : Dict String (List { id : String, pos : Position.Grid })
                                nodesByKind =
                                    nodes |> List.groupBy (\n -> n.id |> String.split "/" |> List.headOr "") |> Dict.mapValues (List.map (\n -> { id = n.id |> String.split "/" |> List.drop 1 |> String.join "/", pos = Position.grid n.pos }))

                                tablePositions : Dict TableId Position.Grid
                                tablePositions =
                                    nodesByKind |> Dict.getOrElse "table" [] |> List.filterMap (\n -> n.id |> TableId.fromString |> Maybe.map (\id -> { id = id, pos = n.pos })) |> List.indexBy .id |> Dict.mapValues .pos

                                rowNodes : Dict TableRow.Id Position.Grid
                                rowNodes =
                                    nodesByKind |> Dict.getOrElse "row" [] |> List.filterMap (\n -> n.id |> TableRow.fromString |> Maybe.map (\id -> { id = id, pos = n.pos })) |> List.indexBy .id |> Dict.mapValues .pos

                                memoNodes : Dict MemoId Position.Grid
                                memoNodes =
                                    nodesByKind |> Dict.getOrElse "memo" [] |> List.filterMap (\n -> n.id |> MemoId.fromString |> Maybe.map (\id -> { id = id, pos = n.pos })) |> List.indexBy .id |> Dict.mapValues .pos
                            in
                            layout
                                |> mapTables (List.map (\t -> tablePositions |> Dict.get t.id |> Maybe.mapOrElse (\pos -> t |> mapProps (setPosition pos)) t))
                                |> mapTableRows (List.map (\r -> rowNodes |> Dict.get r.id |> Maybe.mapOrElse (\p -> r |> setPosition p) r))
                                |> mapMemos (List.map (\m -> memoNodes |> Dict.get m.id |> Maybe.mapOrElse (\p -> m |> setPosition p) m))
                                |> fitCanvasAlgo erdElem tables rows memos groups
                                |> (\( newLayout, extra ) -> ( newLayout, extra |> Extra.setHistory ( SetLayout_ layout, SetLayout_ newLayout ) ))
                        )
                    |> Extra.defaultT
            )
        |> Maybe.withDefault ( erd, "No table to arrange in the canvas" |> Toasts.create "warning" |> Toast |> Extra.msg )


objectsToFit : ErdLayout -> Maybe ( List TableId, ( List TableRow.Id, List MemoId, List Area.Canvas ) )
objectsToFit layout =
    let
        selectedTables : List ErdTableLayout
        selectedTables =
            layout.tables |> List.filter (.props >> .selected)
    in
    if selectedTables /= [] then
        Just ( selectedTables |> List.map .id, ( [], [], [] ) )

    else if layout.tables /= [] || layout.tableRows /= [] || layout.memos /= [] then
        Just
            ( layout.tables |> List.map .id
            , ( layout.tableRows |> List.map .id
              , layout.memos |> List.map .id
              , layout.groups |> List.zipWithIndex |> List.filterMap (ErdTableLayout.buildGroupArea layout.tables) |> List.map Tuple3.third
              )
            )

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
