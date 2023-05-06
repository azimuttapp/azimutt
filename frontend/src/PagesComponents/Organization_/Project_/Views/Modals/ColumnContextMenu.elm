module PagesComponents.Organization_.Project_.Views.Modals.ColumnContextMenu exposing (view, viewHidden)

import Components.Molecules.ContextMenu as ContextMenu
import Conf
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Models.Notes exposing (Notes)
import Libs.Models.Platform exposing (Platform)
import Models.Project.ColumnRef exposing (ColumnRef)
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), VirtualRelationMsg(..))
import PagesComponents.Organization_.Project_.Models.NotesMsg exposing (NotesMsg(..))


view : Platform -> Int -> ColumnRef -> Maybe Notes -> Html Msg
view platform index column notes =
    div [ class "z-max" ]
        [ div [ class "px-4 py-1 text-sm font-medium leading-6 text-gray-500" ] [ text (column.column.head ++ " column") ]
        , ContextMenu.btn "" (DetailsSidebarMsg (DetailsSidebar.ShowColumn column)) [ text "Show details" ]
        , ContextMenu.btnHotkey "" (HideColumn column) [ text "Hide column" ] platform (Conf.hotkeys |> Dict.getOrElse "hide" [])
        , ContextMenu.btnHotkey "" (NotesMsg (NOpen column.table (Just column.column))) [ text (notes |> Maybe.mapOrElse (\_ -> "Update notes") "Add notes") ] platform (Conf.hotkeys |> Dict.getOrElse "notes" [])
        , ContextMenu.btnHotkey "" (VirtualRelationMsg (VRCreate (Just column))) [ text "Add relation" ] platform (Conf.hotkeys |> Dict.getOrElse "create-virtual-relation" [])
        , ContextMenu.btn "" (MoveColumn column (index - 1)) [ text "Move up" ]
        , ContextMenu.btn "" (MoveColumn column (index + 1)) [ text "Move down" ]
        , ContextMenu.btn "" (MoveColumn column 0) [ text "Move top" ]
        , ContextMenu.btn "" (MoveColumn column 100) [ text "Move bottom" ]
        ]


viewHidden : Platform -> Int -> ColumnRef -> Maybe String -> Html Msg
viewHidden platform _ column _ =
    div []
        [ ContextMenu.btnHotkey "" (ShowColumn column) [ text "Show column" ] platform (Conf.hotkeys |> Dict.getOrElse "show" [])
        ]
