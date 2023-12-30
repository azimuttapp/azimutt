module PagesComponents.Organization_.Project_.Updates.TableRow exposing (deleteTableRow, mapTableRowOrSelected, moveToTableRow, showTableRow, unDeleteTableRow)

import Components.Organisms.TableRow as TableRow
import DataSources.DbMiner.DbTypes exposing (RowQuery)
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
import Services.Lenses exposing (mapCanvasT, mapPositionT, mapTableRows, mapTableRowsSeq, mapTableRowsT)
import Set exposing (Set)
import Time
import Track


showTableRow : Time.Posix -> DbSourceInfo -> RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> String -> Erd -> ( Erd, ( Cmd Msg, List ( Msg, Msg ) ) )
showTableRow now source query previous hint from erd =
    let
        hidden : Set ColumnName
        hidden =
            erd |> Erd.currentLayout |> .tableRows |> List.find (\r -> r.source == source.id && r.table == query.table) |> Maybe.mapOrElse .hidden Set.empty

        ( row, cmd ) =
            TableRow.init erd.project erd.tableRowsSeq now source query hidden previous hint
    in
    ( erd
        |> mapTableRowsSeq (\i -> i + 1)
        |> Erd.mapCurrentLayoutWithTime now (mapTableRows (List.prepend row))
    , ( Cmd.batch [ cmd, Ports.observeTableRowSize row.id, Track.tableRowShown source from erd.project ]
      , [ ( DeleteTableRow row.id, UnDeleteTableRow_ 0 row ) ]
      )
    )


deleteTableRow : TableRow.Id -> ErdLayout -> ( ErdLayout, ( Cmd Msg, List ( Msg, Msg ) ) )
deleteTableRow id layout =
    layout
        |> mapTableRowsT
            (\rows ->
                case rows |> List.zipWithIndex |> List.partition (\( r, _ ) -> r.id == id) of
                    ( ( deleted, index ) :: _, kept ) ->
                        ( kept |> List.map Tuple.first, ( Cmd.none, [ ( UnDeleteTableRow_ index deleted, DeleteTableRow deleted.id ) ] ) )

                    _ ->
                        ( rows, ( Cmd.none, [] ) )
            )


unDeleteTableRow : Int -> TableRow -> ErdLayout -> ( ErdLayout, ( Cmd Msg, List ( Msg, Msg ) ) )
unDeleteTableRow index tableRow layout =
    layout |> mapTableRowsT (\rows -> ( rows |> List.insertAt index tableRow, ( Ports.observeTableRowSize tableRow.id, [ ( DeleteTableRow tableRow.id, UnDeleteTableRow_ index tableRow ) ] ) ))


moveToTableRow : Time.Posix -> ErdProps -> TableRow -> Erd -> ( Erd, Maybe ( Cmd Msg, List ( Msg, Msg ) ) )
moveToTableRow now viewport row erd =
    erd |> Erd.mapCurrentLayoutTWithTime now (mapCanvasT (centerTableRow viewport row)) |> Tuple.mapSecond (Maybe.map (\h -> ( Cmd.none, h )))


centerTableRow : ErdProps -> TableRow -> CanvasProps -> ( CanvasProps, List ( Msg, Msg ) )
centerTableRow viewport row canvas =
    let
        rowCenter : Position.Viewport
        rowCenter =
            row |> Area.centerCanvasGrid |> Position.canvasToViewport viewport.position canvas.position canvas.zoom

        delta : Delta
        delta =
            viewport |> Area.centerViewport |> Position.diffViewport rowCenter
    in
    canvas |> mapPositionT (\pos -> pos |> Position.moveDiagram delta |> (\newPos -> ( newPos, [ ( CanvasPosition_ pos, CanvasPosition_ newPos ) ] )))


mapTableRowOrSelected : TableRow.Id -> TableRow.Msg -> (TableRow -> ( TableRow, ( Cmd msg, List ( msg, msg ) ) )) -> List TableRow -> ( List TableRow, ( Cmd msg, List ( msg, msg ) ) )
mapTableRowOrSelected id msg f rows =
    rows
        |> List.findBy .id id
        |> Maybe.map
            (\r ->
                if r.selected && TableRow.canBroadcast msg then
                    rows |> List.mapByT .selected True f |> Tuple.mapSecond (List.unzip >> Tuple.mapBoth Cmd.batch List.concat)

                else
                    rows |> List.mapByT .id id f |> Tuple.mapSecond (List.unzip >> Tuple.mapBoth Cmd.batch List.concat)
            )
        |> Maybe.withDefault ( rows, ( Cmd.none, [] ) )
