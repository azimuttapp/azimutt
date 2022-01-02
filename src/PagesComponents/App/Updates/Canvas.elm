module PagesComponents.App.Updates.Canvas exposing (computeFit, fitCanvas, handleWheel, performZoom, resetCanvas, zoomCanvas)

import Conf
import Dict exposing (Dict)
import Libs.Area as Area exposing (Area)
import Libs.Bool as B
import Libs.DomInfo exposing (DomInfo)
import Libs.Html.Events exposing (WheelEvent)
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Models.Project exposing (Project, tablesArea, viewportArea, viewportSize)
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.Layout exposing (Layout)
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.App.Updates.Helpers exposing (setCanvas, setLayout, setTables)


handleWheel : WheelEvent -> CanvasProps -> CanvasProps
handleWheel event canvas =
    if event.ctrl then
        canvas |> performZoom (-event.delta.dy * Conf.canvas.zoom.speed) event.position

    else
        canvas |> performMove event.delta.dx event.delta.dy


zoomCanvas : Dict HtmlId DomInfo -> Float -> CanvasProps -> CanvasProps
zoomCanvas domInfos delta canvas =
    viewportSize domInfos |> M.mapOrElse (\size -> canvas |> performZoom delta (viewportArea size canvas |> Area.center)) canvas


fitCanvas : Dict HtmlId DomInfo -> Layout -> Layout
fitCanvas domInfos layout =
    viewportSize domInfos
        |> M.mapOrElse
            (\size ->
                let
                    viewport : Area
                    viewport =
                        viewportArea size layout.canvas

                    selectedTables : List TableProps
                    selectedTables =
                        layout.tables |> List.filter .selected

                    contentArea : Area
                    contentArea =
                        tablesArea domInfos (B.cond (selectedTables |> List.isEmpty) layout.tables selectedTables)

                    padding : Float
                    padding =
                        20

                    ( newZoom, centerOffset ) =
                        computeFit viewport padding contentArea layout.canvas.zoom
                in
                layout
                    |> setCanvas (\c -> { c | position = Position.zero, zoom = newZoom })
                    |> setTables (\tables -> tables |> List.map (\t -> { t | position = t.position |> Position.add centerOffset }))
            )
            layout


performMove : Float -> Float -> CanvasProps -> CanvasProps
performMove left top canvas =
    let
        newLeft : Float
        newLeft =
            canvas.position.left - (left * canvas.zoom)

        newTop : Float
        newTop =
            canvas.position.top - (top * canvas.zoom)
    in
    { canvas | position = Position newLeft newTop }


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
    { canvas | position = Position newLeft newTop, zoom = newZoom }


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


resetCanvas : Project -> Project
resetCanvas project =
    { project | usedLayout = Nothing }
        |> setLayout (\l -> { l | tables = [], hiddenTables = [], canvas = project.layout.canvas |> (\c -> { c | position = { left = 0, top = 0 }, zoom = 1 }) })
