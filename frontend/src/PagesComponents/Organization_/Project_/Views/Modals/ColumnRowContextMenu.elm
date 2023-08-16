module PagesComponents.Organization_.Project_.Views.Modals.ColumnRowContextMenu exposing (view, viewHidden)

import Components.Molecules.ContextMenu as ContextMenu
import Conf
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Models.Notes exposing (Notes)
import Libs.Models.Platform exposing (Platform)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableRow exposing (TableRow, TableRowValue)


view : (ColumnName -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> Platform -> TableRow -> TableRowValue -> Maybe Notes -> Html msg
view toggleColumn openNotes platform row value notes =
    div [ class "z-max" ]
        [ div [ class "px-4 py-1 text-sm font-medium leading-6 text-gray-500" ] [ text (value.column ++ " column") ]
        , ContextMenu.btnHotkey "" (toggleColumn value.column) [ text "Hide column" ] platform (Conf.hotkeys |> Dict.getOrElse "hide" [])
        , ContextMenu.btnHotkey "" (openNotes row.query.table (value.column |> ColumnPath.fromString |> Just)) [ text (notes |> Maybe.mapOrElse (\_ -> "Update notes") "Add notes") ] platform (Conf.hotkeys |> Dict.getOrElse "notes" [])
        ]


viewHidden : (ColumnName -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> Platform -> TableRow -> TableRowValue -> Maybe Notes -> Html msg
viewHidden toggleColumn openNotes platform row value notes =
    div []
        [ ContextMenu.btnHotkey "" (toggleColumn value.column) [ text "Show column" ] platform (Conf.hotkeys |> Dict.getOrElse "show" [])
        , ContextMenu.btnHotkey "" (openNotes row.query.table (value.column |> ColumnPath.fromString |> Just)) [ text (notes |> Maybe.mapOrElse (\_ -> "Update notes") "Add notes") ] platform (Conf.hotkeys |> Dict.getOrElse "notes" [])
        ]
