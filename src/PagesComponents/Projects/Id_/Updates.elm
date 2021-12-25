module PagesComponents.Projects.Id_.Updates exposing (updateSizes)

import Conf
import Libs.Area as Area exposing (Area)
import Libs.Bool as B
import Libs.Maybe as M
import Libs.Models exposing (SizeChange)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size
import Models.Project.CanvasProps as CanvasProps
import Models.Project.TableId as TableId
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.App.Updates.Helpers exposing (setCanvas, setCurrentLayout, setTableProps)
import PagesComponents.Projects.Id_.Models exposing (Model, Msg)


updateSizes : List SizeChange -> Model -> ( Model, Cmd Msg )
updateSizes changes model =
    ( changes |> List.sortBy (\c -> B.cond (c.id == Conf.ids.erd) 0 1) |> List.foldl updateSize model, Cmd.none )


updateSize : SizeChange -> Model -> Model
updateSize change model =
    if change.id == Conf.ids.erd then
        model |> setCurrentLayout (setCanvas (\c -> { c | origin = change.position, size = change.size }))

    else
        model |> setTableProps (TableId.fromHtmlId change.id) (updateTable (model.project |> M.mapOrElse (\p -> p.layout.canvas |> CanvasProps.viewport) Area.zero) change)


updateTable : Area -> SizeChange -> TableProps -> TableProps
updateTable viewport change props =
    if props.size == Size.zero && props.position == Position.zero then
        let
            left : Float
            left =
                viewport.position.left + change.seeds.left * max 0 (viewport.size.width - change.size.width)

            top : Float
            top =
                viewport.position.top + change.seeds.top * max 0 (viewport.size.height - change.size.height)
        in
        { props | position = Position left top, size = change.size }

    else
        { props | size = change.size }
