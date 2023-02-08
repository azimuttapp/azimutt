module PagesComponents.Organization_.Project_.Views.Modals.ColumnContextMenu exposing (view, viewHidden)

import Components.Molecules.ContextMenu as ContextMenu
import Conf
import Html exposing (Html, div, text)
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Models.Platform exposing (Platform)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.ColumnRef exposing (ColumnRef)
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), VirtualRelationMsg(..))
import PagesComponents.Organization_.Project_.Models.Notes as NoteRef
import PagesComponents.Organization_.Project_.Models.NotesMsg exposing (NotesMsg(..))


view : Platform -> Int -> ColumnRef -> Maybe String -> Html Msg
view platform index column notes =
    let
        isRoot : Bool
        isRoot =
            column.column |> ColumnPath.isRoot

        root : ColumnRef
        root =
            { column | column = column.column |> ColumnPath.root }
    in
    div []
        ([ Just (ContextMenu.btn "" (DetailsSidebarMsg (DetailsSidebar.ShowColumn root)) [ text "Show details" ])
         , Just (ContextMenu.btnHotkey "" (HideColumn column) [ text "Hide column" ] platform (Conf.hotkeys |> Dict.getOrElse "hide" []))
         , Just (ContextMenu.btnHotkey "" (NotesMsg (NOpen (NoteRef.fromColumn column))) [ text (notes |> Maybe.mapOrElse (\_ -> "Update notes") "Add notes") ] platform (Conf.hotkeys |> Dict.getOrElse "notes" []))

         -- FIXME: add nested columns in AML to allow relations between them
         , Maybe.when isRoot (ContextMenu.btnHotkey "" (VirtualRelationMsg (VRCreate (Just column))) [ text "Add relation" ] platform (Conf.hotkeys |> Dict.getOrElse "create-virtual-relation" []))
         , Maybe.when isRoot (ContextMenu.btn "" (MoveColumn column (index - 1)) [ text "Move up" ])
         , Maybe.when isRoot (ContextMenu.btn "" (MoveColumn column (index + 1)) [ text "Move down" ])
         , Maybe.when isRoot (ContextMenu.btn "" (MoveColumn column 0) [ text "Move top" ])
         , Maybe.when isRoot (ContextMenu.btn "" (MoveColumn column 100) [ text "Move bottom" ])
         ]
            |> List.filterMap identity
        )


viewHidden : Platform -> Int -> ColumnRef -> Maybe String -> Html Msg
viewHidden platform _ column _ =
    div []
        [ ContextMenu.btnHotkey "" (ShowColumn column) [ text "Show column" ] platform (Conf.hotkeys |> Dict.getOrElse "show" [])
        ]
