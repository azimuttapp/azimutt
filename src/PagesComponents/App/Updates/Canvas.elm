module PagesComponents.App.Updates.Canvas exposing (computeFit, fitCanvas, handleWheel, performZoom, zoomCanvas)

import Conf exposing (conf)
import Dict exposing (Dict)
import Libs.Area as Area exposing (Area)
import Libs.Html.Events exposing (WheelEvent)
import Libs.Models exposing (HtmlId, ZoomLevel)
import Libs.Position as Position exposing (Position)
import Libs.Size as Size exposing (Size)
import Models.Project exposing (CanvasProps, Layout, tablesArea, viewportArea, viewportSize)
import PagesComponents.App.Updates.Helpers exposing (setCanvas, setTables)


handleWheel : WheelEvent -> CanvasProps -> CanvasProps
handleWheel event canvas =
    if event.keys.ctrl then
        canvas |> performZoom (event.delta.y * conf.zoom.speed) (Position event.mouse.x event.mouse.y)

    else
        canvas |> performMove event.delta.x event.delta.y


zoomCanvas : Dict HtmlId Size -> Float -> CanvasProps -> CanvasProps
zoomCanvas sizes delta canvas =
    viewportSize sizes |> Maybe.map (\size -> canvas |> performZoom delta (Area.center (viewportArea size canvas))) |> Maybe.withDefault canvas


fitCanvas : Dict HtmlId Size -> Layout -> Layout
fitCanvas sizes layout =
    viewportSize sizes
        |> Maybe.map
            (\size ->
                let
                    viewport : Area
                    viewport =
                        viewportArea size layout.canvas

                    contentArea : Area
                    contentArea =
                        tablesArea sizes layout.tables

                    padding : Float
                    padding =
                        20

                    ( newZoom, centerOffset ) =
                        computeFit viewport padding contentArea layout.canvas.zoom
                in
                layout
                    |> setCanvas (\c -> { c | position = Position 0 0, zoom = newZoom })
                    |> setTables (\tables -> tables |> List.map (\t -> { t | position = t.position |> Position.add centerOffset }))
            )
        |> Maybe.withDefault layout


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
            (canvas.zoom + delta) |> clamp conf.zoom.min conf.zoom.max

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
        viewportSize : Size
        viewportSize =
            viewport |> Area.size |> Size.sub (2 * padding / zoom)

        contentSize : Size
        contentSize =
            content |> Area.size

        grow : Size
        grow =
            viewportSize |> Size.ratio contentSize

        newZoom : ZoomLevel
        newZoom =
            (zoom * min grow.width grow.height) |> clamp conf.zoom.min conf.zoom.max

        growFactor : Float
        growFactor =
            newZoom / zoom

        newViewport : Area
        newViewport =
            viewport |> Area.scale (1 / growFactor)

        newViewportCenter : Position
        newViewportCenter =
            newViewport |> Area.center |> Position.sub (Position newViewport.left newViewport.top)

        newContentCenter : Position
        newContentCenter =
            content |> Area.center

        offset : Position
        offset =
            newViewportCenter |> Position.sub newContentCenter
    in
    ( newZoom, offset )
