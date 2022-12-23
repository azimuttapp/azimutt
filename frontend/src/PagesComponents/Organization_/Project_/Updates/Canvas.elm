module PagesComponents.Organization_.Project_.Updates.Canvas exposing (arrangeTables, computeFit, fitCanvas, handleWheel, performZoom, zoomCanvas)

import Conf
import Dagre as D
import Dagre.Attributes as DA
import Dict exposing (Dict)
import Graph
import Libs.Bool as B
import Libs.Html.Events exposing (WheelEvent)
import Libs.Models.Delta as Delta exposing (Delta)
import Libs.Models.Position as Position
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Nel as Nel exposing (Nel)
import Libs.Task as T
import Models.Area as Area
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId exposing (TableId)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models exposing (Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import Services.Lenses exposing (mapCanvas, mapPosition, mapProps, mapTables, setPosition, setZoom)
import Services.Toasts as Toasts
import Time


handleWheel : WheelEvent -> ErdProps -> CanvasProps -> CanvasProps
handleWheel event erdElem canvas =
    if event.ctrl then
        canvas |> performZoom erdElem (-event.delta.dy * Conf.canvas.zoom.speed * canvas.zoom) event.clientPos

    else
        { canvas | position = canvas.position |> Position.moveDiagram (event.delta |> Delta.negate |> Delta.adjust canvas.zoom) }


zoomCanvas : Float -> ErdProps -> CanvasProps -> CanvasProps
zoomCanvas delta erdElem canvas =
    canvas |> performZoom erdElem delta (erdElem |> Area.centerViewport)


fitCanvas : Time.Posix -> ErdProps -> Erd -> ( Erd, Cmd Msg )
fitCanvas now erdElem erd =
    (erd |> Erd.currentLayout |> selectedTablesOrAll |> List.map .id |> Nel.fromList)
        |> Maybe.map (\tables -> ( erd |> Erd.mapCurrentLayoutWithTime now (fitCanvasAlgo erdElem tables), Cmd.none ))
        |> Maybe.withDefault ( erd, "No table to fit into the canvas" |> Toasts.create "warning" |> Toast |> T.send )


fitCanvasAlgo : ErdProps -> Nel TableId -> ErdLayout -> ErdLayout
fitCanvasAlgo erdElem tables layout =
    (layout.tables |> List.filter (\t -> tables |> Nel.member t.id) |> List.map (.props >> Area.offGrid))
        |> Area.mergeCanvas
        |> Maybe.map
            (\tablesArea ->
                let
                    ( newZoom, centerOffset ) =
                        computeFit (layout.canvas |> CanvasProps.viewport erdElem) Conf.constants.canvasMargins tablesArea layout.canvas.zoom
                in
                layout
                    |> mapCanvas (setPosition Position.zeroDiagram >> setZoom newZoom)
                    |> mapTables (List.map (mapProps (mapPosition (Position.moveGrid centerOffset))))
            )
        |> Maybe.withDefault layout


arrangeTables : Time.Posix -> ErdProps -> Erd -> ( Erd, Cmd Msg )
arrangeTables now erdElem erd =
    -- Improvement: fit only selected tables if there is some, use `selectedTablesOrAll` instead of `.tables`
    -- For that, they need to stay in "the same area", but it will probably extend a lot... Maybe keep the center?
    (erd |> Erd.currentLayout |> .tables |> List.map .id |> Nel.fromList)
        -- TODO: instead of pipe into fitCanvasAlgo, use layout width/height to fit in the viewport?
        |> Maybe.map (\tables -> ( erd |> Erd.mapCurrentLayoutWithTime now (arrangeTablesAlgo tables >> fitCanvasAlgo erdElem tables), Cmd.none ))
        |> Maybe.withDefault ( erd, "No table to arrange in the canvas" |> Toasts.create "warning" |> Toast |> T.send )


arrangeTablesAlgo : Nel TableId -> ErdLayout -> ErdLayout
arrangeTablesAlgo tables layout =
    let
        nodes : List (Graph.Node ErdTableLayout)
        nodes =
            layout.tables |> List.filter (\t -> tables |> Nel.member t.id) |> List.indexedMap Graph.Node

        asNodeId : Dict TableId Graph.NodeId
        asNodeId =
            nodes |> List.map (\n -> ( n.label.id, n.id )) |> Dict.fromList

        edges : List (Graph.Edge ())
        edges =
            nodes |> List.concatMap (\n -> n.label.relatedTables |> Dict.filter (\_ -> .shown) |> Dict.keys |> List.filterMap (\id -> asNodeId |> Dict.get id) |> List.map (\n2 -> Graph.Edge n.id n2 ()))

        diagram : D.GraphLayout
        diagram =
            D.runLayout
                [ DA.rankDir DA.LR
                , DA.widthDict (nodes |> List.map (\n -> ( n.id, n.label.props.size |> Size.extractCanvas |> .width )) |> Dict.fromList)
                , DA.heightDict (nodes |> List.map (\n -> ( n.id, n.label.props.size |> Size.extractCanvas |> .height )) |> Dict.fromList)
                ]
                (Graph.fromNodesAndEdges nodes edges)

        updatePosition : ErdTableLayout -> ErdTableLayout
        updatePosition t =
            (asNodeId |> Dict.get t.id)
                |> Maybe.andThen (\id -> diagram.coordDict |> Dict.get id |> Maybe.map (Position.fromTuple >> Position.grid))
                |> Maybe.map (\pos -> t |> mapProps (setPosition pos))
                |> Maybe.withDefault t
    in
    layout |> mapTables (List.map updatePosition)


selectedTablesOrAll : ErdLayout -> List ErdTableLayout
selectedTablesOrAll layout =
    let
        selectedTables : List ErdTableLayout
        selectedTables =
            layout.tables |> List.filter (.props >> .selected)
    in
    B.cond (List.isEmpty selectedTables) layout.tables selectedTables


performZoom : ErdProps -> Float -> Position.Viewport -> CanvasProps -> CanvasProps
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


computeFit : Area.Canvas -> Float -> Area.Canvas -> ZoomLevel -> ( ZoomLevel, Delta )
computeFit erdViewport padding content zoom =
    let
        -- FIXME: seems bad when aspect ratio are different
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
