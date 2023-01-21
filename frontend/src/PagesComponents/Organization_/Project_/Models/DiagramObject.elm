module PagesComponents.Organization_.Project_.Models.DiagramObject exposing (DiagramObject, area, fromMemo, fromTable, position, size, toMemo, toTable)

import Models.Area as Area
import Models.Position as Position
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)


type DiagramObject
    = Table ErdTableLayout
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

        Memo m ->
            { position = m.position, size = m.size }


position : DiagramObject -> Position.Grid
position o =
    o |> area |> .position


size : DiagramObject -> Size.Canvas
size o =
    o |> area |> .size
