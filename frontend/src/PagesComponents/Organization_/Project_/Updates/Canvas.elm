module PagesComponents.Organization_.Project_.Updates.Canvas exposing (arrangeTables, computeFit, fitCanvas, handleWheel, performZoom, squashViewHistory, zoomCanvas)

import Conf
import Dagre as D
import Dagre.Attributes as DA
import Dict exposing (Dict)
import Graph
import Libs.Html.Events exposing (WheelEvent)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Delta as Delta exposing (Delta)
import Libs.Models.Position as Position
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Task as T
import Libs.Tuple3 as Tuple3
import Models.Area as Area
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableRow as TableRow exposing (TableRow)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models exposing (Model, Msg(..))
import PagesComponents.Organization_.Project_.Models.DiagramObject as DiagramObject exposing (DiagramObject)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout as ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId exposing (MemoId)
import Services.Lenses exposing (mapMemos, mapPosition, mapProps, mapTableRows, mapTables, setCanvas, setLayoutOnLoad, setPosition)
import Services.Toasts as Toasts
import Time


handleWheel : WheelEvent -> ErdProps -> CanvasProps -> ( CanvasProps, ( Cmd Msg, List ( Msg, Msg ) ) )
handleWheel event erdElem canvas =
    if event.ctrl then
        canvas |> performZoom erdElem (-event.delta.dy * Conf.canvas.zoom.speed * canvas.zoom) event.clientPos

    else
        { canvas | position = canvas.position |> Position.moveDiagram (event.delta |> Delta.negate |> Delta.adjust canvas.zoom) }
            |> (\new -> ( new, ( Cmd.none, [ ( SetView_ canvas, SetView_ new ) ] ) ))


zoomCanvas : Float -> ErdProps -> CanvasProps -> ( CanvasProps, ( Cmd Msg, List ( Msg, Msg ) ) )
zoomCanvas delta erdElem canvas =
    canvas |> performZoom erdElem delta (erdElem |> Area.centerViewport)


fitCanvas : ErdProps -> Erd -> ( Erd, Maybe ( Cmd Msg, List ( Msg, Msg ) ) )
fitCanvas erdElem erd =
    (erd |> Erd.currentLayout |> objectsToFit)
        |> Maybe.map (\( tables, ( rows, memos, groups ) ) -> erd |> setLayoutOnLoad "" |> Erd.mapCurrentLayoutT (fitCanvasAlgo erdElem tables rows memos groups))
        |> Maybe.withDefault ( erd, Just ( "No table to fit into the canvas" |> Toasts.create "warning" |> Toast |> T.send, [] ) )


fitCanvasAlgo : ErdProps -> List TableId -> List TableRow.Id -> List MemoId -> List Area.Canvas -> ErdLayout -> ( ErdLayout, ( Cmd Msg, List ( Msg, Msg ) ) )
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
                , ( Cmd.none, [ ( SetView_ (layout.canvas |> mapPosition (Position.moveDiagram (Delta.negate centerOffset))), SetView_ canvas ) ] )
                )
            )
        |> Maybe.withDefault ( layout, ( Cmd.none, [] ) )


arrangeTables : Time.Posix -> ErdProps -> Erd -> ( Erd, Maybe ( Cmd Msg, List ( Msg, Msg ) ) )
arrangeTables now erdElem erd =
    -- TODO: toggle this on show all tables if layout was empty before, see frontend/src/PagesComponents/Organization_/Project_/Updates/Table.elm:106#showAllTables
    (erd |> Erd.currentLayout |> objectsToFit)
        |> Maybe.map
            (\( tables, ( rows, memos, groups ) ) ->
                erd
                    |> setLayoutOnLoad ""
                    |> Erd.mapCurrentLayoutTWithTime now
                        (\layout ->
                            layout
                                |> arrangeTablesAlgo tables rows memos
                                |> Tuple.mapFirst (fitCanvasAlgo erdElem tables rows memos groups)
                                |> (\( ( l, ( c2, _ ) ), ( c1, _ ) ) -> ( l, ( Cmd.batch [ c1, c2 ], [ ( SetLayout_ layout, SetLayout_ l ) ] ) ))
                        )
            )
        |> Maybe.withDefault ( erd, Just ( "No table to arrange in the canvas" |> Toasts.create "warning" |> Toast |> T.send, [] ) )


arrangeTablesAlgo : List TableId -> List TableRow.Id -> List MemoId -> ErdLayout -> ( ErdLayout, ( Cmd Msg, List ( Msg, Msg ) ) )
arrangeTablesAlgo tables rows memos layout =
    let
        nodes : List (Graph.Node DiagramObject)
        nodes =
            ((layout.tables |> List.filterInBy .id tables |> List.map DiagramObject.fromTable)
                ++ (layout.tableRows |> List.filterInBy .id rows |> List.map DiagramObject.fromTableRow)
                ++ (layout.memos |> List.filterInBy .id memos |> List.map DiagramObject.fromMemo)
            )
                |> List.indexedMap Graph.Node

        initialContentArea : Maybe Area.Canvas
        initialContentArea =
            (nodes |> List.map (.label >> DiagramObject.area >> Area.offGrid)) |> Area.mergeCanvas

        tableNodeId : Dict TableId Graph.NodeId
        tableNodeId =
            nodes |> List.filterMap (\n -> n.label |> DiagramObject.toTable |> Maybe.map (\t -> ( t.id, n.id ))) |> Dict.fromList

        tableRowNodeId : Dict TableRow.Id Graph.NodeId
        tableRowNodeId =
            nodes |> List.filterMap (\n -> n.label |> DiagramObject.toTableRow |> Maybe.map (\r -> ( r.id, n.id ))) |> Dict.fromList

        memoNodeId : Dict MemoId Graph.NodeId
        memoNodeId =
            nodes |> List.filterMap (\n -> n.label |> DiagramObject.toMemo |> Maybe.map (\m -> ( m.id, n.id ))) |> Dict.fromList

        edges : List (Graph.Edge ())
        edges =
            nodes
                |> List.filterMap (\n -> n.label |> DiagramObject.toTable |> Maybe.map (\t -> ( n, t )))
                |> List.concatMap (\( n, t ) -> t.relatedTables |> Dict.filter (\_ -> .shown) |> Dict.keys |> List.filterMap (\id -> tableNodeId |> Dict.get id) |> List.map (\n2 -> Graph.Edge n.id n2 ()))

        diagram : D.GraphLayout
        diagram =
            D.runLayout
                [ DA.rankDir DA.LR
                , DA.widthDict (nodes |> List.map (\n -> ( n.id, n.label |> DiagramObject.size |> Size.extractCanvas |> .width )) |> Dict.fromList)
                , DA.heightDict (nodes |> List.map (\n -> ( n.id, n.label |> DiagramObject.size |> Size.extractCanvas |> .height )) |> Dict.fromList)
                ]
                (Graph.fromNodesAndEdges nodes edges)

        positions : Dict Graph.NodeId Position.Canvas
        positions =
            diagram.coordDict |> Dict.map (\_ -> Position.fromTuple >> Position.canvas)

        finalContentArea : Maybe Area.Canvas
        finalContentArea =
            positions |> Dict.values |> List.reduce Position.minCanvas |> Maybe.map (\p -> { position = p, size = Size.canvas diagram })

        delta : Delta
        delta =
            -- keep same top-left position for the content area
            Maybe.map2 (\i f -> i.position |> Position.diffCanvas f.position) initialContentArea finalContentArea |> Maybe.withDefault Delta.zero

        getPosition : Graph.NodeId -> Maybe Position.Grid
        getPosition id =
            positions |> Dict.get id |> Maybe.map (Position.moveCanvas delta >> Position.onGrid)
    in
    layout
        |> mapTables (List.map (\t -> tableNodeId |> Dict.get t.id |> Maybe.andThen getPosition |> Maybe.mapOrElse (\p -> t |> mapProps (setPosition p)) t))
        |> mapTableRows (List.map (\r -> tableRowNodeId |> Dict.get r.id |> Maybe.andThen getPosition |> Maybe.mapOrElse (\p -> r |> setPosition p) r))
        |> mapMemos (List.map (\m -> memoNodeId |> Dict.get m.id |> Maybe.andThen getPosition |> Maybe.mapOrElse (\p -> m |> setPosition p) m))
        |> (\l -> ( l, ( Cmd.none, [ ( SetLayout_ layout, SetLayout_ l ) ] ) ))


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


performZoom : ErdProps -> Float -> Position.Viewport -> CanvasProps -> ( CanvasProps, ( Cmd Msg, List ( Msg, Msg ) ) )
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
        |> (\newCanvas -> ( newCanvas, ( Cmd.none, [ ( SetView_ canvas, SetView_ newCanvas ) ] ) ))


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


squashViewHistory : ( Model, Cmd Msg, List ( Msg, Msg ) ) -> ( Model, Cmd Msg, List ( Msg, Msg ) )
squashViewHistory ( model, cmd, history ) =
    case ( model.history, history ) of
        ( ( SetView_ first, SetView_ _ ) :: rest, [ ( SetView_ _, SetView_ last ) ] ) ->
            ( { model | history = rest }, cmd, [ ( SetView_ first, SetView_ last ) ] )

        _ ->
            ( model, cmd, history )
