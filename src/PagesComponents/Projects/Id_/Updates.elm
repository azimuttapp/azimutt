module PagesComponents.Projects.Id_.Updates exposing (updateSizes)

import Conf
import Dict exposing (Dict)
import Libs.Area as Area exposing (Area, AreaLike)
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Models exposing (SizeChange)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Models.Project.CanvasProps as CanvasProps
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (Model, Msg)
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import PagesComponents.Projects.Id_.Models.PositionHint exposing (PositionHint(..))
import Services.Lenses exposing (mapErdM, mapScreen, mapTableProps, setPosition, setSize)


updateSizes : List SizeChange -> Model -> ( Model, Cmd Msg )
updateSizes changes model =
    ( changes |> List.sortBy (\c -> B.cond (c.id == Conf.ids.erd) 0 1) |> List.foldl updateSize model, Cmd.none )


updateSize : SizeChange -> Model -> Model
updateSize change model =
    if change.id == Conf.ids.erd then
        model |> mapScreen (setPosition change.position >> setSize change.size)

    else
        ( TableId.fromHtmlId change.id, model.erd |> Maybe.mapOrElse (.canvas >> CanvasProps.viewport model.screen) Area.zero )
            |> (\( tableId, viewport ) -> model |> mapErdM (mapTableProps (\props -> props |> Dict.alter tableId (updateTable props viewport change))))


updateTable : Dict TableId ErdTableProps -> Area -> SizeChange -> ErdTableProps -> ErdTableProps
updateTable allProps viewport change props =
    if props.size == Size.zero && props.position == Position.zero then
        props
            |> ErdTableProps.setSize change.size
            |> ErdTableProps.setPosition (computeInitialPosition allProps viewport change props.positionHint)

    else
        props |> ErdTableProps.setSize change.size


computeInitialPosition : Dict TableId ErdTableProps -> Area -> SizeChange -> Maybe PositionHint -> Position
computeInitialPosition allProps viewport change hint =
    hint
        |> Maybe.mapOrElse
            (\h ->
                case h of
                    PlaceLeft position ->
                        position |> Position.sub { left = change.size.width + 50, top = 0 } |> moveDownIfExists (allProps |> Dict.values) change.size

                    PlaceRight position size ->
                        position |> Position.add { left = size.width + 50, top = 0 } |> moveDownIfExists (allProps |> Dict.values) change.size
            )
            (if allProps |> Dict.filter (\_ p -> p.size /= Size.zero) |> Dict.isEmpty then
                viewport |> Area.center |> Position.sub (change |> Area.center)

             else
                { left = viewport.position.left + change.seeds.left * max 0 (viewport.size.width - change.size.width)
                , top = viewport.position.top + change.seeds.top * max 0 (viewport.size.height - change.size.height)
                }
            )


moveDownIfExists : List ErdTableProps -> Size -> Position -> Position
moveDownIfExists allProps size position =
    if allProps |> List.any (\p -> p.position == position || isSameTopRight p (Area position size)) then
        position |> Position.add { left = 0, top = Conf.ui.tableHeaderHeight } |> moveDownIfExists allProps size

    else
        position


isSameTopRight : AreaLike x -> AreaLike y -> Bool
isSameTopRight a b =
    a.position.top == b.position.top && a.position.left + a.size.width == b.position.left + b.size.width
