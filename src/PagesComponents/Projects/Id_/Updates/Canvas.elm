module PagesComponents.Projects.Id_.Updates.Canvas exposing (computeFit, fitCanvas, handleWheel, performZoom, zoomCanvas)

import Conf
import Libs.Area as Area exposing (Area)
import Libs.Bool as B
import Libs.Delta as Delta
import Libs.Html.Events exposing (WheelEvent)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.ScreenProps exposing (ScreenProps)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)
import Services.Lenses exposing (mapCanvas, mapPosition, mapProps, mapTables, setPosition, setZoom)
import Time


handleWheel : WheelEvent -> CanvasProps -> CanvasProps
handleWheel event canvas =
    if event.ctrl then
        canvas |> performZoom (-event.delta.dy * Conf.canvas.zoom.speed) event.position

    else
        { canvas | position = event.delta |> Delta.negate |> Delta.adjust canvas.zoom |> Delta.move canvas.position }


zoomCanvas : Float -> ScreenProps -> CanvasProps -> CanvasProps
zoomCanvas delta screen canvas =
    canvas |> performZoom delta (canvas |> CanvasProps.viewport screen |> Area.center)


fitCanvas : Time.Posix -> ScreenProps -> Erd -> Erd
fitCanvas now screen erd =
    let
        layout : ErdLayout
        layout =
            erd |> Erd.currentLayout

        selectedTables : List ErdTableLayout
        selectedTables =
            layout.tables |> List.filter (.props >> .selected)

        tables : List ErdTableLayout
        tables =
            B.cond (List.isEmpty selectedTables) layout.tables selectedTables

        tablesArea : Area
        tablesArea =
            tables |> List.map .props |> Area.merge |> Maybe.withDefault Area.zero

        padding : Float
        padding =
            20

        ( newZoom, centerOffset ) =
            computeFit (layout.canvas |> CanvasProps.viewport screen) padding tablesArea layout.canvas.zoom
    in
    erd
        |> Erd.mapCurrentLayout now
            (mapCanvas (setPosition Position.zero >> setZoom newZoom)
                >> mapTables (List.map (mapProps (mapPosition (Position.add centerOffset >> Position.stepBy Conf.canvas.grid))))
            )


performZoom : Float -> Position -> CanvasProps -> CanvasProps
performZoom delta center canvas =
    -- TODO fix small vertical deviation
    let
        newZoom : ZoomLevel
        newZoom =
            (canvas.zoom + delta) |> clamp Conf.canvas.zoom.min Conf.canvas.zoom.max

        zoomFactor : Float
        zoomFactor =
            newZoom / canvas.zoom

        -- to zoom on cursor, works only if origin is top left (CSS property: "transform-origin: top left;")
        newLeft : Float
        newLeft =
            canvas.position.left - ((center.left - canvas.position.left) * (zoomFactor - 1))

        newTop : Float
        newTop =
            canvas.position.top - ((center.top - canvas.position.top) * (zoomFactor - 1))
    in
    { position = Position newLeft newTop, zoom = newZoom }


computeFit : Area -> Float -> Area -> ZoomLevel -> ( ZoomLevel, Position )
computeFit viewport padding content zoom =
    let
        newZoom : ZoomLevel
        newZoom =
            computeZoom viewport padding content zoom

        growFactor : Float
        growFactor =
            newZoom / zoom

        newViewport : Area
        newViewport =
            viewport |> Area.div growFactor

        newViewportCenter : Position
        newViewportCenter =
            newViewport |> Area.center |> Position.sub newViewport.position

        newContentCenter : Position
        newContentCenter =
            content |> Area.center

        offset : Position
        offset =
            newViewportCenter |> Position.sub newContentCenter
    in
    ( newZoom, offset )


computeZoom : Area -> Float -> Area -> Float -> ZoomLevel
computeZoom viewport padding content zoom =
    let
        viewportSize : Size
        viewportSize =
            viewport.size |> Size.sub (2 * padding / zoom)

        grow : Size
        grow =
            viewportSize |> Size.ratio content.size

        newZoom : ZoomLevel
        newZoom =
            (zoom * min grow.width grow.height) |> clamp Conf.canvas.zoom.min 1
    in
    newZoom
