module PagesComponents.Projects.Id_.Updates exposing (updateSizes)

import Conf
import Libs.Area as Area exposing (Area)
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Maybe as M
import Libs.Models exposing (SizeChange)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size
import Models.Project.CanvasProps as CanvasProps
import Models.Project.TableId as TableId
import PagesComponents.Projects.Id_.Models exposing (Model, Msg)
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import Services.Lenses exposing (mapErdM, mapScreen, mapTableProps, setPosition, setSize)


updateSizes : List SizeChange -> Model -> ( Model, Cmd Msg )
updateSizes changes model =
    ( changes |> List.sortBy (\c -> B.cond (c.id == Conf.ids.erd) 0 1) |> List.foldl updateSize model, Cmd.none )


updateSize : SizeChange -> Model -> Model
updateSize change model =
    if change.id == Conf.ids.erd then
        model |> mapScreen (setPosition change.position >> setSize change.size)

    else
        ( TableId.fromHtmlId change.id, model.erd |> M.mapOrElse (.canvas >> CanvasProps.viewport model.screen) Area.zero )
            |> (\( tableId, viewport ) -> model |> mapErdM (mapTableProps (Dict.alter tableId (updateTable viewport change))))


updateTable : Area -> SizeChange -> ErdTableProps -> ErdTableProps
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
        props |> ErdTableProps.setSize change.size |> ErdTableProps.setPosition (Position left top)

    else
        props |> ErdTableProps.setSize change.size
