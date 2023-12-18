module PagesComponents.Organization_.Project_.Views.Modals.ErdContextMenu exposing (view)

import Components.Molecules.ContextMenu as ContextMenu
import Components.Slices.DataExplorer as DataExplorer
import Components.Slices.NewLayoutBody as NewLayoutBody
import Conf
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Libs.Dict as Dict
import Libs.Html.Events exposing (PointerEvent)
import Libs.Maybe as Maybe
import Libs.Models.Platform exposing (Platform)
import Models.ErdProps exposing (ErdProps)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models exposing (AmlSidebarMsg(..), FindPathMsg(..), GroupMsg(..), MemoMsg(..), Msg(..), SchemaAnalysisMsg(..))
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Views.Modals.NewLayout as NewLayout


view : Platform -> ErdProps -> CanvasProps -> ErdLayout -> PointerEvent -> Html Msg
view platform erdElem canvasProps layout event =
    let
        selectedTables : List TableId
        selectedTables =
            layout.tables |> List.filter (\t -> t.props.selected) |> List.map .id
    in
    div [ class "z-max" ]
        [ ContextMenu.btnHotkey "" (Focus Conf.ids.searchInput) [] [ text "Add more tables" ] platform (Conf.hotkeys |> Dict.getOrElse "search-open" [])
        , ContextMenu.btn "" (AmlSidebarMsg AToggle) [] [ text "Update your schema" ]
        , ContextMenu.btnHotkey "" (DataExplorerMsg (DataExplorer.Open Nothing Nothing)) [] [ text "Explore your database content" ] platform []
        , ContextMenu.btnHotkey "" (NewLayoutMsg (NewLayout.Open NewLayoutBody.Create)) [] [ text "New layout" ] platform (Conf.hotkeys |> Dict.getOrElse "create-layout" [])
        , ContextMenu.btnHotkey "" (event |> CanvasProps.eventCanvas erdElem canvasProps |> MCreate |> MemoMsg) [] [ text "New memo" ] platform (Conf.hotkeys |> Dict.getOrElse "new-memo" [])
        , selectedTables |> List.head |> Maybe.mapOrElse (\_ -> ContextMenu.btnHotkey "" (GCreate selectedTables |> GroupMsg) [] [ text "New group" ] platform (Conf.hotkeys |> Dict.getOrElse "create-group" [])) (div [] [])
        , ContextMenu.btnHotkey "" SelectAll [] [ text "Select all" ] platform (Conf.hotkeys |> Dict.getOrElse "select-all" [])
        , ContextMenu.btn "" FitToScreen [] [ text "Fit diagram to screen" ]
        , ContextMenu.btnHotkey "" (FindPathMsg (FPOpen Nothing Nothing)) [] [ text "Find path between tables" ] platform (Conf.hotkeys |> Dict.getOrElse "find-path" [])
        , ContextMenu.btn "" (SchemaAnalysisMsg SAOpen) [] [ text "Analyze schema" ]
        ]
