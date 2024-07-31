module PagesComponents.Organization_.Project_.Updates.TableRow exposing (deleteTableRow, mapTableRowOrSelected, moveToTableRow, showTableRow, unDeleteTableRow)

import Components.Organisms.TableRow as TableRow
import DataSources.DbMiner.DbTypes exposing (RowQuery)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Delta exposing (Delta)
import Libs.Result as Result
import Models.Area as Area
import Models.DbSourceInfoWithUrl as DbSourceInfoWithUrl
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.TableRow as TableRow exposing (TableRow)
import PagesComponents.Organization_.Project_.Models exposing (Model, Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Ports
import Services.Lenses exposing (mapCanvasT, mapPositionT, mapTableRows, mapTableRowsSeq, mapTableRowsT)
import Services.Toasts as Toasts
import Set exposing (Set)
import Time
import Track


showTableRow : Time.Posix -> RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> String -> Erd -> ( Erd, Extra Msg )
showTableRow now query previous hint from erd =
    (erd.sources |> List.findBy .id query.source |> Result.fromMaybe ("source missing (" ++ SourceId.toString query.source ++ ")") |> Result.andThen DbSourceInfoWithUrl.fromSource)
        |> Result.fold
            (\err -> ( erd, "Can't show row: " ++ err |> Toasts.create "warning" |> Toast |> Extra.msg ))
            (\source ->
                let
                    hidden : Set ColumnName
                    hidden =
                        erd |> Erd.currentLayout |> .tableRows |> List.find (\r -> r.source == query.source && r.table == query.table) |> Maybe.mapOrElse .hidden Set.empty

                    ( row, cmd ) =
                        TableRow.init erd.project erd.tableRowsSeq now source query hidden previous hint
                in
                ( erd
                    |> mapTableRowsSeq (\i -> i + 1)
                    |> Erd.mapCurrentLayoutWithTime now (mapTableRows (List.prepend row))
                , Extra.newLL
                    [ cmd, Ports.observeTableRowSize row.id, Track.tableRowShown source from erd.project ]
                    (previous |> Maybe.mapOrElse (\_ -> [ ( DeleteTableRow row.id, UnDeleteTableRow_ 0 row ) ]) [])
                  -- don't add history if loading, add it when loaded (see frontend/src/Components/Organisms/TableRow.elm#update GotResult)
                )
            )


deleteTableRow : TableRow.Id -> ErdLayout -> ( ErdLayout, Extra Msg )
deleteTableRow id layout =
    layout
        |> mapTableRowsT
            (\rows ->
                case rows |> List.zipWithIndex |> List.partition (\( r, _ ) -> r.id == id) of
                    ( ( deleted, index ) :: _, kept ) ->
                        ( kept |> List.map Tuple.first, Extra.history ( UnDeleteTableRow_ index deleted, DeleteTableRow deleted.id ) )

                    _ ->
                        ( rows, Extra.none )
            )


unDeleteTableRow : Int -> TableRow -> ErdLayout -> ( ErdLayout, Extra Msg )
unDeleteTableRow index tableRow layout =
    layout |> mapTableRowsT (\rows -> ( rows |> List.insertAt index tableRow, Extra.new (Ports.observeTableRowSize tableRow.id) ( DeleteTableRow tableRow.id, UnDeleteTableRow_ index tableRow ) ))


moveToTableRow : Time.Posix -> ErdProps -> TableRow -> Erd -> ( Erd, Extra Msg )
moveToTableRow now viewport row erd =
    erd |> Erd.mapCurrentLayoutTWithTime now (mapCanvasT (centerTableRow viewport row)) |> Extra.defaultT


centerTableRow : ErdProps -> TableRow -> CanvasProps -> ( CanvasProps, Extra Msg )
centerTableRow viewport row canvas =
    let
        rowCenter : Position.Viewport
        rowCenter =
            row |> Area.centerCanvasGrid |> Position.canvasToViewport viewport.position canvas.position canvas.zoom

        delta : Delta
        delta =
            viewport |> Area.centerViewport |> Position.diffViewport rowCenter
    in
    canvas |> mapPositionT (\pos -> pos |> Position.moveDiagram delta |> (\newPos -> ( newPos, Extra.history ( CanvasPosition pos, CanvasPosition newPos ) )))


mapTableRowOrSelected : TableRow.Id -> TableRow.Msg -> (TableRow -> ( TableRow, Extra msg )) -> List TableRow -> ( List TableRow, Extra msg )
mapTableRowOrSelected id msg f rows =
    rows
        |> List.findBy .id id
        |> Maybe.map
            (\r ->
                if r.selected && TableRow.canBroadcast msg then
                    rows |> List.mapByT .selected True f |> Tuple.mapSecond Extra.concat

                else
                    rows |> List.mapByT .id id f |> Tuple.mapSecond Extra.concat
            )
        |> Maybe.withDefault ( rows, Extra.none )
