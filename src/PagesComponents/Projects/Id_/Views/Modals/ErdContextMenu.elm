module PagesComponents.Projects.Id_.Views.Modals.ErdContextMenu exposing (view)

import Components.Molecules.ContextMenu as ContextMenu
import Conf
import Html exposing (Html, div, text)
import Libs.Dict as Dict
import Libs.Models.Platform exposing (Platform)
import PagesComponents.Projects.Id_.Models exposing (AmlSidebarMsg(..), FindPathMsg(..), LayoutMsg(..), Msg(..), SchemaAnalysisMsg(..))


view : Platform -> Html Msg
view platform =
    div []
        [ ContextMenu.btnHotkey "" SelectAllTables [ text "Select all tables" ] platform (Conf.hotkeys |> Dict.getOrElse "select-all" [])
        , ContextMenu.btnHotkey "" (LayoutMsg (LOpen Nothing)) [ text "New layout" ] platform (Conf.hotkeys |> Dict.getOrElse "create-layout" [])
        , ContextMenu.btn "" FitContent [ text "Fit diagram to screen" ]
        , ContextMenu.btn "" (AmlSidebarMsg AToggle) [ text "Update schema" ]
        , ContextMenu.btnHotkey "" (FindPathMsg (FPOpen Nothing Nothing)) [ text "Find path between tables" ] platform (Conf.hotkeys |> Dict.getOrElse "find-path" [])
        , ContextMenu.btn "" (SchemaAnalysisMsg SAOpen) [ text "Analyze schema" ]
        ]
