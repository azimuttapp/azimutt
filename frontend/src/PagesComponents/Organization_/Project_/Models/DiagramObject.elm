module PagesComponents.Organization_.Project_.Models.DiagramObject exposing (DiagramObject, area, fromMemo, fromTable, fromTableRow, position, size, toMemo, toTable, toTableRow)

import Models.Area as Area
import Models.Position as Position
import Models.Project.TableRow exposing (TableRow)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)


type DiagramObject
    = Table ErdTableLayout
    | TableRow TableRow
    | Memo Memo


fromTable : ErdTableLayout -> DiagramObject
fromTable t =
    Table t


toTable : DiagramObject -> Maybe ErdTableLayout
toTable o =
    case o of
        Table t ->
            Just t

        _ ->
            Nothing


fromTableRow : TableRow -> DiagramObject
fromTableRow r =
    TableRow r


toTableRow : DiagramObject -> Maybe TableRow
toTableRow o =
    case o of
        TableRow r ->
            Just r

        _ ->
            Nothing


fromMemo : Memo -> DiagramObject
fromMemo m =
    Memo m


toMemo : DiagramObject -> Maybe Memo
toMemo o =
    case o of
        Memo m ->
            Just m

        _ ->
            Nothing


area : DiagramObject -> Area.Grid
area o =
    case o of
        Table t ->
            { position = t.props.position, size = t.props.size }

        TableRow r ->
            { position = r.position, size = r.size }

        Memo m ->
            { position = m.position, size = m.size }


position : DiagramObject -> Position.Grid
position o =
    o |> area |> .position


size : DiagramObject -> Size.Canvas
size o =
    o |> area |> .size
