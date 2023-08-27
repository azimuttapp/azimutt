module PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout, create, createMemo, empty, isEmpty, nonEmpty, unpack)

import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.Models.Size exposing (Size)
import Models.Position as Position
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.Group exposing (Group)
import Models.Project.Layout exposing (Layout)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableRow exposing (TableRow)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout as ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId exposing (MemoId)
import Set
import Time


type alias ErdLayout =
    { canvas : CanvasProps
    , tables : List ErdTableLayout -- list order is used for z-index
    , tableRows : List TableRow
    , groups : List Group
    , memos : List Memo
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


empty : Time.Posix -> ErdLayout
empty now =
    { canvas = CanvasProps.empty
    , tables = []
    , tableRows = []
    , groups = []
    , memos = []
    , createdAt = now
    , updatedAt = now
    }


isEmpty : ErdLayout -> Bool
isEmpty layout =
    List.isEmpty layout.tables && List.isEmpty layout.tableRows && List.isEmpty layout.memos


nonEmpty : ErdLayout -> Bool
nonEmpty layout =
    not (isEmpty layout)


create : Dict TableId (List ErdRelation) -> Layout -> ErdLayout
create relationsByTable layout =
    { canvas = CanvasProps.empty
    , tables = layout.tables |> List.map (\t -> t |> ErdTableLayout.create (layout.tables |> List.map .id |> Set.fromList) (relationsByTable |> Dict.getOrElse t.id []))
    , tableRows = layout.tableRows
    , groups = layout.groups
    , memos = layout.memos
    , createdAt = layout.createdAt
    , updatedAt = layout.updatedAt
    }


unpack : ErdLayout -> Layout
unpack layout =
    { tables = layout.tables |> List.map (\t -> t |> ErdTableLayout.unpack)
    , tableRows = layout.tableRows
    , groups = layout.groups
    , memos = layout.memos
    , createdAt = layout.createdAt
    , updatedAt = layout.updatedAt
    }


createMemo : ErdLayout -> Position.Canvas -> Memo
createMemo layout position =
    let
        id : MemoId
        id =
            (layout.memos |> List.map .id |> List.maximum |> Maybe.withDefault 0) + 1
    in
    { id = id
    , content = ""
    , position = position |> Position.moveCanvas { dx = -75, dy = -75 } |> Position.onGrid
    , size = Size 150 150 |> Size.canvas
    , color = Nothing
    , selected = False
    }
