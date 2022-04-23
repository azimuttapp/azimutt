module PagesComponents.Projects.Id_.Views.Modals.ColumnContextMenu exposing (viewColumnContextMenu, viewHiddenColumnContextMenu)

import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Conf
import Dict
import Html exposing (Html, div, text)
import Libs.Hotkey as Hotkey
import Libs.Maybe as Maybe
import Models.Project.ColumnRef exposing (ColumnRef)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), NotesMsg(..))
import PagesComponents.Projects.Id_.Models.Notes as NoteRef


viewColumnContextMenu : Int -> ColumnRef -> Maybe String -> Html Msg
viewColumnContextMenu index column notes =
    div []
        [ ContextMenu.btnHotkey (HideColumn column) "Hide column" (Conf.hotkeys |> Dict.get "remove" |> Maybe.andThen List.head |> Maybe.map Hotkey.keys)
        , ContextMenu.btn "" (NotesMsg (NOpen (NoteRef.fromColumn column))) [ text (notes |> Maybe.mapOrElse (\_ -> "Update notes") "Add notes") ]
        , ContextMenu.btn "" (MoveColumn column (index - 1)) [ text "Move up" ]
        , ContextMenu.btn "" (MoveColumn column (index + 1)) [ text "Move down" ]
        , ContextMenu.btn "" (MoveColumn column 0) [ text "Move top" ]
        , ContextMenu.btn "" (MoveColumn column 100) [ text "Move bottom" ]
        ]


viewHiddenColumnContextMenu : Int -> ColumnRef -> Maybe String -> Html Msg
viewHiddenColumnContextMenu _ column _ =
    div []
        [ ContextMenu.btn "" (ShowColumn column) [ text "Show column" ]
        ]
