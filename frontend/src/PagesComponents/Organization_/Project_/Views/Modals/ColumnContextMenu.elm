module PagesComponents.Organization_.Project_.Views.Modals.ColumnContextMenu exposing (view, viewHidden)

import Components.Atoms.Icon as Icon
import Components.Molecules.ContextMenu as ContextMenu
import Components.Slices.DataExplorer as DataExplorer
import Conf
import DataSources.DbMiner.DbQuery as DbQuery
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, title)
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseKind as DatabaseKind
import Libs.Models.Notes exposing (Notes)
import Libs.Models.Platform exposing (Platform)
import Models.Project.ColumnRef exposing (ColumnRef)
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), VirtualRelationMsg(..))
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.NotesMsg exposing (NotesMsg(..))


view : Platform -> Int -> ColumnRef -> Maybe ErdColumn -> Maybe Notes -> Html Msg
view platform index ref column notes =
    div [ class "z-max" ]
        [ div [ class "px-4 py-1 text-sm font-medium leading-6 text-gray-500" ] [ text (ref.column.head ++ " column") ]
        , ContextMenu.btnHotkey "" (HideColumn ref) [] [ text "Hide column" ] platform (Conf.hotkeys |> Dict.getOrElse "hide" [])
        , ContextMenu.btn "" (DetailsSidebarMsg (DetailsSidebar.ShowColumn ref)) [] [ text "Show details" ]
        , column
            |> Maybe.andThen (\c -> c.origins |> List.findMap (\o -> o.db |> Maybe.andThen DatabaseKind.fromUrl |> Maybe.map (\kind -> ( o.id, kind ))))
            |> Maybe.map (\( id, kind ) -> ContextMenu.btn "" (DataExplorerMsg (DataExplorer.Open (Just id) (Just (DbQuery.exploreColumn kind ref.table ref.column)))) [] [ text "Explore column data" ])
            |> Maybe.withDefault (div [] [])
        , ContextMenu.btnHotkey "" (NotesMsg (NOpen ref.table (Just ref.column))) [] [ text (notes |> Maybe.mapOrElse (\_ -> "Update notes") "Add notes") ] platform (Conf.hotkeys |> Dict.getOrElse "notes" [])
        , ContextMenu.btnHotkey "" (VirtualRelationMsg (VRCreate (Just ref))) [] [ text "Add relation" ] platform (Conf.hotkeys |> Dict.getOrElse "create-virtual-relation" [])
        , ContextMenu.btn "" (MoveColumn ref (index - 1)) [ title "Move up" ] [ text "Move", Icon.solid Icon.ChevronUp "ml-1 w-4 h-4 inline" ]
        , ContextMenu.btn "" (MoveColumn ref (index + 1)) [ title "Move down" ] [ text "Move", Icon.solid Icon.ChevronDown "ml-1 w-4 h-4 inline" ]
        , ContextMenu.btn "" (MoveColumn ref 0) [ title "Move top" ] [ text "Move", Icon.solid Icon.ChevronDoubleUp "ml-1 w-4 h-4 inline" ]
        , ContextMenu.btn "" (MoveColumn ref 100) [ title "Move bottom" ] [ text "Move", Icon.solid Icon.ChevronDoubleDown "ml-1 w-4 h-4 inline" ]
        ]


viewHidden : Platform -> Int -> ColumnRef -> Maybe ErdColumn -> Maybe Notes -> Html Msg
viewHidden platform _ column erdColumn notes =
    div []
        [ ContextMenu.btnHotkey "" (ShowColumn 1000 column) [] [ text "Show column" ] platform (Conf.hotkeys |> Dict.getOrElse "show" [])
        , ContextMenu.btn "" (DetailsSidebarMsg (DetailsSidebar.ShowColumn column)) [] [ text "Show details" ]
        , erdColumn
            |> Maybe.andThen (\c -> c.origins |> List.findMap (\o -> o.db |> Maybe.andThen DatabaseKind.fromUrl |> Maybe.map (\kind -> ( o.id, kind ))))
            |> Maybe.map (\( id, kind ) -> ContextMenu.btn "" (DataExplorerMsg (DataExplorer.Open (Just id) (Just (DbQuery.exploreColumn kind column.table column.column)))) [] [ text "Explore column data" ])
            |> Maybe.withDefault (div [] [])
        , ContextMenu.btnHotkey "" (NotesMsg (NOpen column.table (Just column.column))) [] [ text (notes |> Maybe.mapOrElse (\_ -> "Update notes") "Add notes") ] platform (Conf.hotkeys |> Dict.getOrElse "notes" [])
        , ContextMenu.btnHotkey "" (VirtualRelationMsg (VRCreate (Just column))) [] [ text "Add relation" ] platform (Conf.hotkeys |> Dict.getOrElse "create-virtual-relation" [])
        ]
