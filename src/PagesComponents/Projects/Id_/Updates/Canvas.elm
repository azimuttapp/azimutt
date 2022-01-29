module PagesComponents.Projects.Id_.Updates.Canvas exposing (fitCanvas, handleWheel, zoomCanvas)

import Conf
import Dict exposing (Dict)
import Libs.Area as Area exposing (Area)
import Libs.Bool as B
import Libs.Delta as Delta
import Libs.Html.Events exposing (WheelEvent)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId exposing (TableId)
import Models.ScreenProps exposing (ScreenProps)
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import Services.Lenses exposing (mapCanvas, mapTableProps, setPosition, setZoom)


handleWheel : WheelEvent -> CanvasProps -> CanvasProps
handleWheel event canvas =
    if event.ctrl then
        canvas |> performZoom (-event.delta.dy * Conf.canvas.zoom.speed) event.position

    else
        { canvas | position = event.delta |> Delta.negate |> Delta.adjust canvas.zoom |> Delta.move canvas.position }


zoomCanvas : Float -> ScreenProps -> CanvasProps -> CanvasProps
zoomCanvas delta screen canvas =
    canvas |> performZoom delta (canvas |> CanvasProps.viewport screen |> Area.center)


fitCanvas : ScreenProps -> Erd -> Erd
fitCanvas screen erd =
    let
        selectedTables : Dict TableId ErdTableProps
        selectedTables =
            erd.tableProps |> Dict.filter (\_ p -> p.selected)

        tables : Dict TableId ErdTableProps
        tables =
            B.cond (selectedTables |> Dict.isEmpty) erd.tableProps selectedTables

        tablesArea : Area
        tablesArea =
            tables |> Dict.values |> List.map ErdTableProps.area |> Area.merge |> Maybe.withDefault Area.zero

        padding : Float
        padding =
            20

        ( newZoom, centerOffset ) =
            computeFit (erd.canvas |> CanvasProps.viewport screen) padding tablesArea erd.canvas.zoom
    in
    erd
        |> mapCanvas (setPosition Position.zero >> setZoom newZoom)
        |> mapTableProps (Dict.map (\_ -> ErdTableProps.mapPosition (Position.add centerOffset)))


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
