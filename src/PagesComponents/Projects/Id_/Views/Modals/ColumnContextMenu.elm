module PagesComponents.Projects.Id_.Views.Modals.ColumnContextMenu exposing (viewColumnContextMenu, viewHiddenColumnContextMenu)

import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Conf
import Dict
import Html exposing (Html, div, text)
import Libs.Hotkey as Hotkey
import Models.Project.ColumnRef exposing (ColumnRef)
import PagesComponents.Projects.Id_.Models exposing (Msg(..))


viewColumnContextMenu : Int -> ColumnRef -> Html Msg
viewColumnContextMenu index column =
    div []
        [ ContextMenu.btnHotkey (HideColumn column) "Hide column" (Conf.hotkeys |> Dict.get "remove" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys)
        , ContextMenu.btn "" (MoveColumn column (index - 1)) [ text "Move up" ]
        , ContextMenu.btn "" (MoveColumn column (index + 1)) [ text "Move down" ]
        , ContextMenu.btn "" (MoveColumn column 0) [ text "Move top" ]
        , ContextMenu.btn "" (MoveColumn column 100) [ text "Move bottom" ]
        ]


viewHiddenColumnContextMenu : Int -> ColumnRef -> Html Msg
viewHiddenColumnContextMenu _ column =
    div []
        [ ContextMenu.btn "" (ShowColumn column) [ text "Show column" ]
        ]
