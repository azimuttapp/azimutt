module PagesComponents.Organization_.Project_.Updates.TableRow exposing (moveToTableRow, showTableRow)

import Components.Organisms.TableRow as TableRow
import Libs.List as List
import Libs.Models.Delta exposing (Delta)
import Models.Area as Area
import Models.DbSourceInfo exposing (DbSourceInfo)
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.TableRow as TableRow exposing (TableRow)
import PagesComponents.Organization_.Project_.Models exposing (Model, Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import Ports
import Services.Lenses exposing (mapCanvas, mapPosition, mapTableRows, mapTableRowsSeq)
import Services.QueryBuilder as QueryBuilder
import Time


showTableRow : Time.Posix -> DbSourceInfo -> QueryBuilder.RowQuery -> Maybe TableRow.SuccessState -> Erd -> ( Erd, Cmd Msg )
showTableRow now source query previous erd =
    let
        ( row, cmd ) =
            TableRow.init erd.tableRowsSeq now source query previous
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
