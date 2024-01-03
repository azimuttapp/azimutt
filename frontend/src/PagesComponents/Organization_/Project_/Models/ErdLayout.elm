module PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout, ErdLayoutItem, create, createMemo, empty, getSelected, isEmpty, mapSelected, nonEmpty, setSelected, unpack)

import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Size exposing (Size)
import Models.Position as Position
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.Group exposing (Group)
import Models.Project.Layout exposing (Layout)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableRow as TableRow exposing (TableRow)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout as ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import PagesComponents.Organization_.Project_.Models.MemoId as MemoId exposing (MemoId)
import Services.Lenses as Lenses exposing (mapMemos, mapProps, mapTableRows, mapTables)
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


type alias ErdLayoutItem =
    { id : HtmlId, position : Position.Grid, size : Size.Canvas }


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


getSelected : ErdLayout -> List HtmlId
getSelected layout =
    (layout.tables |> List.filter (.props >> .selected) |> List.map (.id >> TableId.toHtmlId))
        ++ (layout.tableRows |> List.filter .selected |> List.map (.id >> TableRow.toHtmlId))
        ++ (layout.memos |> List.filter .selected |> List.map (.id >> MemoId.toHtmlId))


setSelected : List HtmlId -> ErdLayout -> ErdLayout
setSelected htmlIds layout =
    layout
        |> mapTables (List.map (\t -> t |> mapProps (Lenses.mapSelected (\_ -> htmlIds |> List.member (TableId.toHtmlId t.id)))))
        |> mapTableRows (List.map (\r -> r |> Lenses.mapSelected (\_ -> htmlIds |> List.member (TableRow.toHtmlId r.id))))
        |> mapMemos (List.map (\m -> m |> Lenses.mapSelected (\_ -> htmlIds |> List.member (MemoId.toHtmlId m.id))))


mapSelected : (ErdLayoutItem -> Bool -> Bool) -> ErdLayout -> ErdLayout
mapSelected transform layout =
    layout
        |> mapTables (List.map (\t -> t |> mapProps (Lenses.mapSelected (transform { id = TableId.toHtmlId t.id, position = t.props.position, size = t.props.size }))))
        |> mapTableRows (List.map (\r -> r |> Lenses.mapSelected (transform { id = TableRow.toHtmlId r.id, position = r.position, size = r.size })))
        |> mapMemos (List.map (\m -> m |> Lenses.mapSelected (transform { id = MemoId.toHtmlId m.id, position = m.position, size = m.size })))


createMemo : ErdLayout -> Position.Grid -> Memo
createMemo layout position =
    let
        id : MemoId
        id =
            (layout.memos |> List.map .id |> List.maximum |> Maybe.withDefault 0) + 1
    in
    { id = id
    , content = ""
    , position = position |> Position.moveGrid { dx = -75, dy = -75 }
    , size = Size 150 150 |> Size.canvas
    , color = Nothing
    , selected = False
    }
