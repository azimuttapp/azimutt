module PagesComponents.Organization_.Project_.Views.Commands exposing (argsToString, viewCommands)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Tooltip as Tooltip
import Components.Slices.DataExplorer as DataExplorer
import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class, disabled, id, type_)
import Html.Events exposing (onClick)
import Libs.Basics as Basics
import Libs.Bool as B
import Libs.Html as Html
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Tailwind as Tw exposing (TwClass, batch, focus, hover)
import Models.AutoLayout as AutoLayoutMethod
import PagesComponents.Organization_.Project_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Organization_.Project_.Models exposing (AmlSidebarMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.CursorMode as CursorMode exposing (CursorMode)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)


argsToString : CursorMode -> HtmlId -> HtmlId -> Bool -> Bool -> Bool -> Bool -> String
argsToString cursorMode htmlId openedDropdown layoutNonEmpty amlSidebar detailsSidebar dataExplorer =
    [ CursorMode.toString cursorMode, htmlId, openedDropdown, B.cond layoutNonEmpty "Y" "N", B.cond amlSidebar "Y" "N", B.cond detailsSidebar "Y" "N", B.cond dataExplorer "Y" "N" ] |> String.join "~"


stringToArgs : String -> ( ( CursorMode, HtmlId, HtmlId ), Bool, ( Bool, Bool, Bool ) )
stringToArgs args =
    case args |> String.split "~" of
        [ cursorMode, htmlId, openedDropdown, layoutNonEmpty, amlSidebar, detailsSidebar, dataExplorer ] ->
            ( ( CursorMode.fromString cursorMode, htmlId, openedDropdown ), layoutNonEmpty == "Y", ( amlSidebar == "Y", detailsSidebar == "Y", dataExplorer == "Y" ) )

        _ ->
            ( ( CursorMode.Select, "", "" ), True, ( True, True, True ) )


viewCommands : ErdConf -> ZoomLevel -> List ( Msg, Msg ) -> List ( Msg, Msg ) -> String -> Html Msg
viewCommands conf canvasZoom history future args =
    let
        ( ( cursorMode, htmlId, openedDropdown ), layoutNonEmpty, ( amlSidebar, detailsSidebar, dataExplorer ) ) =
            stringToArgs args

        buttonStyles : TwClass
        buttonStyles =
            batch [ "relative inline-flex items-center p-2 border border-gray-300 text-sm font-medium", focus [ "z-10 outline-none ring-1 ring-primary-500 border-primary-500" ], Tw.disabled [ "cursor-not-allowed bg-gray-100 text-gray-400" ] ]

        classic : TwClass
        classic =
            batch [ "bg-white text-gray-700", hover [ "bg-gray-50" ] ]

        inverted : TwClass
        inverted =
            batch [ "bg-gray-700 text-white", hover [ "bg-gray-600" ] ]
    in
    div [ class "az-commands absolute bottom-0 right-0 m-3 print:hidden" ]
        [ if conf.move && layoutNonEmpty then
            let
                ( historyLen, futureLen ) =
                    ( List.length history, List.length future )
            in
            span [ class "relative z-0 inline-flex shadow-sm rounded-md" ]
                [ button [ type_ "button", onClick FitToScreen, css [ "rounded-l-md", buttonStyles, classic ] ] [ Icon.solid ArrowsExpand "" ]
                    |> Tooltip.t "Fit diagram to screen"
                , button [ type_ "button", onClick Undo, disabled (historyLen == 0), css [ "-ml-px", buttonStyles, classic ] ] [ Icon.solid ArrowCircleLeft "" ]
                    |> Tooltip.t (B.cond (historyLen == 0) "Undo" ("Undo (" ++ String.fromInt historyLen ++ ")"))
                , button [ type_ "button", onClick Redo, disabled (futureLen == 0), css [ "-ml-px", buttonStyles, classic ] ] [ Icon.solid ArrowCircleRight "" ]
                    |> Tooltip.t (B.cond (futureLen == 0) "Redo" ("Redo (" ++ String.fromInt futureLen ++ ")"))
                , Dropdown.dropdown { id = htmlId ++ "-auto-layout", direction = TopLeft, isOpen = openedDropdown == htmlId ++ "-auto-layout" }
                    (\m ->
                        button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup "true", css [ "-ml-px rounded-r-md", buttonStyles, classic ] ]
                            [ Icon.solid CubeTransparent "" ]
                            |> Tooltip.t "Arrange tables"
                    )
                    (\_ ->
                        div []
                            [ ContextMenu.btn "" (ArrangeTables AutoLayoutMethod.Dagre) [] [ text "Dagre layout" ]
                            , ContextMenu.btn "" (ArrangeTables AutoLayoutMethod.CytoRand) [] [ text "Random layout" ]
                            , ContextMenu.btn "" (ArrangeTables AutoLayoutMethod.CytoGrid) [] [ text "Grid layout" ]
                            , ContextMenu.btn "" (ArrangeTables AutoLayoutMethod.CytoCircle) [] [ text "Circle layout" ]
                            , ContextMenu.btn "" (ArrangeTables AutoLayoutMethod.CytoAvsdf) [] [ text "Avsdf layout" ]
                            , ContextMenu.btn "" (ArrangeTables AutoLayoutMethod.CytoBreadth) [] [ text "Breadth layout" ]
                            , ContextMenu.btn "" (ArrangeTables AutoLayoutMethod.CytoCose) [] [ text "Cose layout" ]
                            , ContextMenu.btn "" (ArrangeTables AutoLayoutMethod.CytoDagre) [] [ text "Dagre2 layout" ]
                            , ContextMenu.btn "" (ArrangeTables AutoLayoutMethod.CytoFcose) [] [ text "Force layout" ]
                            ]
                    )
                ]

          else
            Html.none
        , if conf.update then
            span [ class "relative z-0 inline-flex shadow-sm rounded-md ml-2" ]
                [ button [ type_ "button", onClick (DetailsSidebarMsg DetailsSidebar.Toggle), css [ "rounded-l-md", buttonStyles, B.cond detailsSidebar inverted classic ] ] [ Icon.solid Menu "" ]
                    |> B.cond (conf.select && layoutNonEmpty) Tooltip.t Tooltip.tl "Open table list"
                , button [ type_ "button", onClick (DataExplorerMsg (B.cond dataExplorer DataExplorer.Close (DataExplorer.Open Nothing Nothing))), css [ "-ml-px", buttonStyles, B.cond dataExplorer inverted classic ] ] [ Icon.solid Code "" ]
                    |> B.cond (conf.move && layoutNonEmpty) Tooltip.t Tooltip.tl "Explore your data"
                , button [ type_ "button", onClick (AmlSidebarMsg AToggle), css [ "-ml-px rounded-r-md", buttonStyles, B.cond amlSidebar inverted classic ] ] [ Icon.solid Pencil "" ]
                    |> B.cond (conf.move && layoutNonEmpty) Tooltip.t Tooltip.tl "Update your schema"
                ]

          else
            Html.none
        , if conf.move && layoutNonEmpty then
            span [ class "relative z-0 inline-flex shadow-sm rounded-md ml-2" ]
                [ button [ type_ "button", onClick (CursorMode CursorMode.Select), css [ "rounded-l-md", buttonStyles, B.cond (cursorMode == CursorMode.Select) inverted classic ] ] [ Icon.solid CursorClick "" ]
                    |> Tooltip.t "Select tool"
                , button [ type_ "button", onClick (CursorMode CursorMode.Drag), css [ "-ml-px rounded-r-md", buttonStyles, B.cond (cursorMode == CursorMode.Drag) inverted classic ] ] [ Icon.solid Hand "" ]
                    |> Tooltip.t "Drag tool"
                ]

          else
            Html.none
        , if conf.move && layoutNonEmpty then
            span [ class "relative z-0 inline-flex shadow-sm rounded-md ml-2" ]
                [ button [ type_ "button", onClick (Zoom (-canvasZoom / 10)), css [ "rounded-l-md", buttonStyles, classic ] ] [ Icon.solid Minus "" ]
                , Dropdown.dropdown { id = htmlId ++ "-zoom-level", direction = TopLeft, isOpen = openedDropdown == htmlId ++ "-zoom-level" }
                    (\m ->
                        button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup "true", css [ "-ml-px", buttonStyles, classic ] ]
                            [ text (Basics.prettyNumber (canvasZoom * 100) ++ " %") ]
                    )
                    (\_ ->
                        div []
                            [ ContextMenu.btn "" (Zoom (0.05 - canvasZoom)) [] [ text "5%" ]
                            , ContextMenu.btn "" (Zoom (0.25 - canvasZoom)) [] [ text "25%" ]
                            , ContextMenu.btn "" (Zoom (0.5 - canvasZoom)) [] [ text "50%" ]
                            , ContextMenu.btn "" (Zoom (0.8 - canvasZoom)) [] [ text "80%" ]
                            , ContextMenu.btn "" (Zoom (1 - canvasZoom)) [] [ text "100%" ]
                            , ContextMenu.btn "" (Zoom (1.2 - canvasZoom)) [] [ text "120%" ]
                            , ContextMenu.btn "" (Zoom (1.5 - canvasZoom)) [] [ text "150%" ]
                            , ContextMenu.btn "" (Zoom (2 - canvasZoom)) [] [ text "200%" ]
                            , ContextMenu.btn "" (Zoom (5 - canvasZoom)) [] [ text "500%" ]
                            ]
                    )
                , button [ type_ "button", onClick (Zoom (canvasZoom / 10)), css [ "-ml-px rounded-r-md", buttonStyles, classic ] ] [ Icon.solid Plus "" ]
                ]

          else
            Html.none
        , if conf.fullscreen then
            span [ class "relative z-0 inline-flex shadow-sm rounded-md ml-2" ]
                [ button [ type_ "button", onClick (Fullscreen Nothing), css [ "rounded-l-md rounded-r-md", buttonStyles, classic ] ]
                    [ Icon.solid PresentationChartBar "" ]
                    |> Tooltip.tl "View in full screen"
                ]

          else
            Html.none
        ]
