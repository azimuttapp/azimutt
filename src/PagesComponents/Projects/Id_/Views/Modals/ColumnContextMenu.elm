module PagesComponents.Projects.Id_.Views.Modals.ColumnContextMenu exposing (viewColumnContextMenu, viewHiddenColumnContextMenu)

import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Conf
import Html exposing (Html, div, text)
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Models.Platform exposing (Platform)
import Models.Project.ColumnRef exposing (ColumnRef)
import PagesComponents.Projects.Id_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Projects.Id_.Models exposing (Msg(..), NotesMsg(..))
import PagesComponents.Projects.Id_.Models.Notes as NoteRef


viewColumnContextMenu : Platform -> Int -> ColumnRef -> Maybe String -> Html Msg
viewColumnContextMenu platform index column notes =
    div []
        [ ContextMenu.btnHotkey "" (HideColumn column) [ text "Hide column" ] platform (Conf.hotkeys |> Dict.getOrElse "remove" [])
        , ContextMenu.btnHotkey "" (NotesMsg (NOpen (NoteRef.fromColumn column))) [ text (notes |> Maybe.mapOrElse (\_ -> "Update notes") "Add notes") ] platform (Conf.hotkeys |> Dict.getOrElse "notes" [])
        , ContextMenu.btn "" (DetailsSidebarMsg (DetailsSidebar.Open (Just column.table) (Just column.column))) [ text "View details" ]
        , ContextMenu.btn "" (MoveColumn column (index - 1)) [ text "Move up" ]
        , ContextMenu.btn "" (MoveColumn column (index + 1)) [ text "Move down" ]
        , ContextMenu.btn "" (MoveColumn column 0) [ text "Move top" ]
        , ContextMenu.btn "" (MoveColumn column 100) [ text "Move bottom" ]
        ]


viewHiddenColumnContextMenu : Platform -> Int -> ColumnRef -> Maybe String -> Html Msg
viewHiddenColumnContextMenu _ _ column _ =
    div []
        [ ContextMenu.btn "" (ShowColumn column) [ text "Show column" ]
        ]
