module PagesComponents.Projects.Id_.Updates.Canvas exposing (computeFit, fitCanvas, handleWheel, performZoom, zoomCanvas)

import Conf
import Libs.Bool as B
import Libs.Delta as Delta exposing (Delta)
import Libs.Html.Events exposing (WheelEvent)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Task as T
import Models.Area as Area
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Size as Size
import PagesComponents.Projects.Id_.Models exposing (Msg(..))
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)
import Services.Lenses exposing (mapCanvas, mapPosition, mapProps, mapTables, setPosition, setZoom)
import Services.Toasts as Toasts
import Time


handleWheel : WheelEvent -> ErdProps -> CanvasProps -> CanvasProps
handleWheel event erdElem canvas =
    if event.ctrl then
        canvas |> performZoom erdElem (-event.delta.dy * Conf.canvas.zoom.speed) event.clientPos

    else
        { canvas | position = canvas.position |> Position.moveDiagram (event.delta |> Delta.negate |> Delta.adjust canvas.zoom) }


zoomCanvas : Float -> ErdProps -> CanvasProps -> CanvasProps
zoomCanvas delta erdElem canvas =
    canvas |> performZoom erdElem delta (erdElem |> Area.centerViewport)


fitCanvas : Time.Posix -> ErdProps -> Erd -> ( Erd, Cmd Msg )
fitCanvas now erdElem erd =
    let
        padding : Float
        padding =
            20

        layout : ErdLayout
        layout =
            erd |> Erd.currentLayout

        selectedTables : List ErdTableLayout
        selectedTables =
            layout.tables |> List.filter (.props >> .selected)

        tables : List ErdTableLayout
        tables =
            B.cond (List.isEmpty selectedTables) layout.tables selectedTables
    in
    tables
        |> List.map (\t -> { position = t.props.position |> Position.offGrid, size = t.props.size })
        |> Area.mergeCanvas
        |> Maybe.map
            (\tablesArea ->
                let
                    ( newZoom, centerOffset ) =
                        computeFit (layout.canvas |> CanvasProps.viewport erdElem) padding tablesArea layout.canvas.zoom
                in
                ( erd
                    |> Erd.mapCurrentLayoutWithTime now
                        (mapCanvas (setPosition Position.zeroDiagram >> setZoom newZoom)
                            >> mapTables (List.map (mapProps (mapPosition (Position.moveCanvasGrid centerOffset))))
                        )
                , Cmd.none
                )
            )
        |> Maybe.withDefault ( erd, "No table to fit into the canvas" |> Toasts.create "warning" |> Toast |> T.send )


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
