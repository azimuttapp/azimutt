module PagesComponents.Organization_.Project_.Updates.TableRow exposing (mapTableRowOrSelectedCmd, moveToTableRow, showTableRow)

import Components.Organisms.TableRow as TableRow
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Delta exposing (Delta)
import Models.Area as Area
import Models.DbSourceInfo exposing (DbSourceInfo)
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.TableRow as TableRow exposing (TableRow)
import PagesComponents.Organization_.Project_.Models exposing (Model, Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)
import Ports
import Services.Lenses exposing (mapCanvas, mapPosition, mapTableRows, mapTableRowsSeq)
import Services.QueryBuilder as QueryBuilder
import Set exposing (Set)
import Time


mapTableRowOrSelectedCmd : TableRow.Id -> TableRow.Msg -> (TableRow -> ( TableRow, Cmd msg )) -> List TableRow -> ( List TableRow, Cmd msg )
mapTableRowOrSelectedCmd id msg f rows =
    rows
        |> List.findBy .id id
        |> Maybe.map
            (\r ->
                if r.selected && TableRow.canBroadcast msg then
                    rows |> List.mapByCmd .selected True f

                else
                    rows |> List.mapByCmd .id id f
            )
        |> Maybe.withDefault ( rows, Cmd.none )


showTableRow : Time.Posix -> DbSourceInfo -> QueryBuilder.RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> Erd -> ( Erd, Cmd Msg )
showTableRow now source query previous hint erd =
    let
        hidden : Set ColumnName
        hidden =
            erd |> Erd.currentLayout |> .tableRows |> List.find (\r -> r.source == source.id && r.table == query.table) |> Maybe.mapOrElse .hidden Set.empty

        ( row, cmd ) =
            TableRow.init erd.tableRowsSeq now source query hidden previous hint
    in
    ( erd
        |> mapTableRowsSeq (\i -> i + 1)
        |> Erd.mapCurrentLayoutWithTime now (mapTableRows (List.prepend row))
    , Cmd.batch [ cmd, Ports.observeTableRowSize row.id ]
    )


moveToTableRow : Time.Posix -> ErdProps -> TableRow -> Erd -> ( Erd, Cmd Msg )
moveToTableRow now viewport row erd =
    ( erd |> Erd.mapCurrentLayoutWithTime now (mapCanvas (centerTableRow viewport row)), Cmd.none )


centerTableRow : ErdProps -> TableRow -> CanvasProps -> CanvasProps
centerTableRow viewport row canvas =
    let
        rowCenter : Position.Viewport
        rowCenter =
            row |> Area.centerCanvasGrid |> Position.canvasToViewport viewport.position canvas.position canvas.zoom

        delta : Delta
        delta =
            viewport |> Area.centerViewport |> Position.diffViewport rowCenter
    in
    canvas |> mapPosition (Position.moveDiagram delta)
