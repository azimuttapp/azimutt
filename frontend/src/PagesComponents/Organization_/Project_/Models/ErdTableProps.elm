module PagesComponents.Organization_.Project_.Models.ErdTableProps exposing (ErdTableProps, computeColor, create, init)

import Libs.List as List
import Libs.String as String
import Libs.Tailwind as Tw exposing (Color)
import Models.Position as Position
import Models.Project.TableId exposing (TableId)
import Models.Project.TableMeta exposing (TableMeta)
import Models.Project.TableProps exposing (TableProps)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)


type alias ErdTableProps =
    { positionHint : Maybe PositionHint
    , position : Position.Grid
    , size : Size.Canvas
    , color : Color
    , selected : Bool
    , collapsed : Bool
    , showHiddenColumns : Bool
    }


create : TableProps -> ErdTableProps
create props =
    { positionHint = Nothing
    , position = props.position
    , size = props.size
    , color = props.color
    , selected = props.selected
    , collapsed = props.collapsed
    , showHiddenColumns = props.hiddenColumns
    }


init : Bool -> Maybe PositionHint -> Maybe TableMeta -> ErdTable -> ErdTableProps
init collapsed hint meta table =
    { positionHint = hint
    , position = Position.zeroGrid
    , size = Size.zeroCanvas
    , color = meta |> Maybe.andThen .color |> Maybe.withDefault (computeColor table.id)
    , selected = False
    , collapsed = collapsed
    , showHiddenColumns = False
    }


computeColor : TableId -> Color
computeColor ( _, table ) =
    (table |> String.splitWords |> List.head)
        |> Maybe.map (String.plural >> String.hashCode)
        |> Maybe.map (modBy (List.length Tw.list))
        |> Maybe.andThen (\index -> Tw.list |> List.get index)
        |> Maybe.withDefault Tw.default
