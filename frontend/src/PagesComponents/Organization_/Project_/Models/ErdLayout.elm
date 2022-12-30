module PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout, create, createMemo, empty, unpack)

import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.Html.Events exposing (PointerEvent)
import Libs.Models.Size exposing (Size)
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.Layout exposing (Layout)
import Models.Project.Relation exposing (Relation)
import Models.Project.TableId exposing (TableId)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.ErdTableLayout as ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId exposing (MemoId)
import Set
import Time


type alias ErdLayout =
    { canvas : CanvasProps
    , tables : List ErdTableLayout -- list order is used for z-index
    , memos : List Memo
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


empty : Time.Posix -> ErdLayout
empty now =
    { canvas = CanvasProps.empty
    , tables = []
    , memos = []
    , createdAt = now
    , updatedAt = now
    }


create : Dict TableId (List Relation) -> Layout -> ErdLayout
create relationsByTable layout =
    { canvas = layout.canvas
    , tables = layout.tables |> List.map (\t -> t |> ErdTableLayout.create (layout.tables |> List.map .id |> Set.fromList) (relationsByTable |> Dict.getOrElse t.id []))
    , memos = layout.memos
    , createdAt = layout.createdAt
    , updatedAt = layout.updatedAt
    }


unpack : ErdLayout -> Layout
unpack layout =
    { canvas = layout.canvas
    , tables = layout.tables |> List.map (\t -> t |> ErdTableLayout.unpack)
    , memos = layout.memos
    , createdAt = layout.createdAt
    , updatedAt = layout.updatedAt
    }


createMemo : ErdProps -> ErdLayout -> PointerEvent -> Memo
createMemo erdElem layout e =
    let
        id : MemoId
        id =
            (layout.memos |> List.map .id |> List.maximum |> Maybe.withDefault 0) + 1
    in
    { id = id
    , content = "Memo " ++ String.fromInt id ++ " content"
    , position = e.clientPos |> Position.viewportToCanvas erdElem.position layout.canvas.position layout.canvas.zoom |> Position.onGrid
    , size = Size 150 150 |> Size.canvas
    }
