module PagesComponents.Organization_.Project_.Views.Erd.TableRow exposing (viewTableRow)

import Components.Organisms.TableRow as TableRow exposing (TableRowHover, TableRowRelation)
import Components.Slices.DataExplorer as DataExplorer
import Conf
import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (class, classList, id)
import Html.Events.Extra.Mouse exposing (Button(..))
import Libs.Bool as Bool
import Libs.Html.Events exposing (PointerEvent, onPointerDown)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Platform exposing (Platform)
import Libs.Tailwind exposing (Color)
import Models.DbSource exposing (DbSource)
import Models.Position as Position
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableMeta exposing (TableMeta)
import Models.Project.TableRow as TableRow exposing (TableRow)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models exposing (MemoMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode exposing (CursorMode)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.NotesMsg as NotesMsg
import Time


viewTableRow : Time.Posix -> Platform -> ErdConf -> CursorMode -> SchemaName -> HtmlId -> HtmlId -> HtmlId -> Maybe DbSource -> Maybe TableRowHover -> List TableRowRelation -> Color -> Maybe TableMeta -> TableRow -> Html Msg
viewTableRow now platform conf cursorMode defaultSchema openedDropdown openedPopover htmlId source hoverRow rowRelations color tableMeta row =
    let
        dragAttrs : List (Attribute Msg)
        dragAttrs =
            Bool.cond (cursorMode == CursorMode.Drag || not conf.move) [] [ onPointerDown (handlePointerDown htmlId) platform ]
    in
    div ([ class "select-none absolute", classList [ ( "z-max", row.selected ), ( "invisible", row.size == Size.zeroCanvas ) ] ] ++ Position.stylesGrid row.position ++ dragAttrs)
        [ TableRow.view (TableRowMsg row.id) Noop DropdownToggle PopoverOpen ContextMenuCreate SelectItem (\id -> ShowTable id Nothing) HoverTableRow ShowTableRow (DeleteTableRow row.id) (\t c -> NotesMsg.NOpen t c |> NotesMsg) (\s q -> DataExplorer.Open s q |> DataExplorerMsg) now platform conf defaultSchema openedDropdown openedPopover htmlId source hoverRow rowRelations color tableMeta row
        ]


handlePointerDown : HtmlId -> PointerEvent -> Msg
handlePointerDown htmlId e =
    if e.button == MainButton then
        e |> .clientPos |> DragStart htmlId

    else if e.button == MiddleButton then
        e |> .clientPos |> DragStart Conf.ids.erd

    else
        Noop "No match on table row pointer down"
