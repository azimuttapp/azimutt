module PagesComponents.Organization_.Project_.Views.Modals.ErdContextMenu exposing (view)

import Components.Molecules.ContextMenu as ContextMenu
import Conf
import Html exposing (Html, div, text)
import Libs.Dict as Dict
import Libs.Models.Platform exposing (Platform)
import PagesComponents.Organization_.Project_.Models exposing (AmlSidebarMsg(..), FindPathMsg(..), Msg(..), SchemaAnalysisMsg(..))
import PagesComponents.Organization_.Project_.Views.Modals.NewLayout as NewLayout


view : Platform -> Html Msg
view platform =
    div []
        [ ContextMenu.btnHotkey "" SelectAllTables [ text "Select all tables" ] platform (Conf.hotkeys |> Dict.getOrElse "select-all" [])
        , ContextMenu.btnHotkey "" (NewLayoutMsg (NewLayout.Open Nothing)) [ text "New layout" ] platform (Conf.hotkeys |> Dict.getOrElse "create-layout" [])
        , ContextMenu.btn "" FitContent [ text "Fit diagram to screen" ]
        , ContextMenu.btn "" (AmlSidebarMsg AToggle) [ text "Update your schema" ]
        , ContextMenu.btnHotkey "" (FindPathMsg (FPOpen Nothing Nothing)) [ text "Find path between tables" ] platform (Conf.hotkeys |> Dict.getOrElse "find-path" [])
        , ContextMenu.btn "" (SchemaAnalysisMsg SAOpen) [ text "Analyze schema" ]
        ]
