module PagesComponents.Projects.Id_.Updates.Canvas exposing (computeFit, fitCanvas, handleWheel, performZoom, zoomCanvas)

import Conf
import Libs.Bool as B
import Libs.Delta as Delta exposing (Delta)
import Libs.Html.Events exposing (WheelEvent)
import Libs.Models.Position as Position
import Libs.Models.Size as Size exposing (Size)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Task as T
import Models.Area as Area
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
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
        canvas |> performZoom (-event.delta.dy * Conf.canvas.zoom.speed) (event.clientPos |> CanvasProps.adapt erdElem canvas)

    else
        { canvas | position = canvas.position |> Position.moveCanvas (event.delta |> Delta.negate |> Delta.adjust canvas.zoom) }


zoomCanvas : Float -> ErdProps -> CanvasProps -> CanvasProps
zoomCanvas delta erdElem canvas =
    canvas |> performZoom delta (erdElem |> Area.centerViewport |> CanvasProps.adapt erdElem canvas)


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
        |> Area.mergeInCanvas
        |> Maybe.map
            (\tablesArea ->
                let
                    ( newZoom, centerOffset ) =
                        computeFit (layout.canvas |> CanvasProps.viewport erdElem) padding tablesArea layout.canvas.zoom
                in
                ( erd
                    |> Erd.mapCurrentLayout now
                        (mapCanvas (setPosition Position.zeroCanvas >> setZoom newZoom)
                            >> mapTables (List.map (mapProps (mapPosition (Position.moveGrid centerOffset))))
                        )
                , Cmd.none
                )
            )
        |> Maybe.withDefault ( erd, "No table to fit into the canvas" |> Toasts.create "warning" |> Toast |> T.send )


performZoom : Float -> Position.InCanvas -> CanvasProps -> CanvasProps
performZoom delta target canvas =
    -- TODO fix small vertical deviation
    let
        newZoom : ZoomLevel
        newZoom =
            (canvas.zoom + delta) |> clamp Conf.canvas.zoom.min Conf.canvas.zoom.max

        zoomFactor : Float
        zoomFactor =
            newZoom / canvas.zoom

        ( canvasPos, centerPos ) =
            ( canvas.position |> Position.extractCanvas, target |> Position.extractInCanvas )

        newPos : Position.Canvas
        newPos =
            canvas.position
                -- to zoom on cursor, works only if origin is top left (CSS property: "transform-origin: top left;")
                |> Position.moveCanvas
                    { dx = -((centerPos.left - canvasPos.left) * (zoomFactor - 1))
                    , dy = -((centerPos.top - canvasPos.top) * (zoomFactor - 1))
                    }
    in
    { position = newPos, zoom = newZoom }


computeFit : Area.InCanvas -> Float -> Area.InCanvas -> ZoomLevel -> ( ZoomLevel, Delta )
computeFit erdViewport padding content zoom =
    let
        newZoom : ZoomLevel
        newZoom =
            computeZoom erdViewport padding content zoom

        growFactor : Float
        growFactor =
            newZoom / zoom

        newViewport : Area.InCanvas
        newViewport =
            erdViewport |> Area.divInCanvas growFactor

        newViewportCenter : Position.InCanvas
        newViewportCenter =
            newViewport |> Area.centerInCanvas |> Position.subInCanvas newViewport.position

        newContentCenter : Position.InCanvas
        newContentCenter =
            content |> Area.centerInCanvas

        offset : Delta
        offset =
            newViewportCenter |> Position.diffInCanvas newContentCenter
    in
    ( newZoom, offset )


computeZoom : Area.InCanvas -> Float -> Area.InCanvas -> Float -> ZoomLevel
computeZoom erdViewport padding contentArea zoom =
    let
        viewportSize : Size
        viewportSize =
            erdViewport.size |> Size.sub (2 * padding / zoom)

        grow : Size
        grow =
            viewportSize |> Size.ratio contentArea.size

        newZoom : ZoomLevel
        newZoom =
            (zoom * min grow.width grow.height) |> clamp Conf.canvas.zoom.min 1
    in
    newZoom
