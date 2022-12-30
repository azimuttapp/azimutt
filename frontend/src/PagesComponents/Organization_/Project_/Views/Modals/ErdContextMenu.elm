module PagesComponents.Organization_.Project_.Views.Modals.ErdContextMenu exposing (view)

import Components.Molecules.ContextMenu as ContextMenu
import Conf
import Html exposing (Html, div, text)
import Libs.Dict as Dict
import Libs.Html.Events exposing (PointerEvent)
import Libs.Models.Platform exposing (Platform)
import Models.ErdProps exposing (ErdProps)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import PagesComponents.Organization_.Project_.Models exposing (AmlSidebarMsg(..), FindPathMsg(..), MemoMsg(..), Msg(..), SchemaAnalysisMsg(..))
import PagesComponents.Organization_.Project_.Views.Modals.NewLayout as NewLayout


view : Platform -> ErdProps -> CanvasProps -> PointerEvent -> Html Msg
view platform erdElem canvasProps event =
    div []
        [ ContextMenu.btnHotkey "" SelectAllTables [ text "Select all tables" ] platform (Conf.hotkeys |> Dict.getOrElse "select-all" [])
        , ContextMenu.btnHotkey "" (NewLayoutMsg (NewLayout.Open Nothing)) [ text "New layout" ] platform (Conf.hotkeys |> Dict.getOrElse "create-layout" [])
        , ContextMenu.btnHotkey "" (event |> CanvasProps.eventCanvas erdElem canvasProps |> MCreate |> MemoMsg) [ text "New memo" ] platform (Conf.hotkeys |> Dict.getOrElse "new-memo" [])
        , ContextMenu.btn "" FitContent [ text "Fit diagram to screen" ]
        , ContextMenu.btn "" (AmlSidebarMsg AToggle) [ text "Update your schema" ]
        , ContextMenu.btnHotkey "" (FindPathMsg (FPOpen Nothing Nothing)) [ text "Find path between tables" ] platform (Conf.hotkeys |> Dict.getOrElse "find-path" [])
        , ContextMenu.btn "" (SchemaAnalysisMsg SAOpen) [ text "Analyze schema" ]
        ]
