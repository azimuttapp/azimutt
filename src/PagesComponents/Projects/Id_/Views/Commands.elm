module PagesComponents.Projects.Id_.Views.Commands exposing (viewCommands)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Tooltip as Tooltip
import Conf
import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class, id, type_)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html as Html
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Tailwind exposing (TwClass, batch, focus, hover)
import PagesComponents.Projects.Id_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Projects.Id_.Models exposing (AmlSidebarMsg(..), Msg(..))
import PagesComponents.Projects.Id_.Models.CursorMode as CursorMode exposing (CursorMode)
import PagesComponents.Projects.Id_.Models.ErdConf exposing (ErdConf)


viewCommands : ErdConf -> CursorMode -> ZoomLevel -> HtmlId -> Bool -> HtmlId -> Html Msg
viewCommands conf cursorMode canvasZoom htmlId hasTables openedDropdown =
    let
        buttonStyles : TwClass
        buttonStyles =
            batch [ "relative inline-flex items-center p-2 border border-gray-300 text-sm font-medium", focus [ "z-10 outline-none ring-1 ring-primary-500 border-primary-500" ] ]

        classic : TwClass
        classic =
            batch [ "bg-white text-gray-700", hover [ "bg-gray-50" ] ]

        inverted : TwClass
        inverted =
            batch [ "bg-gray-700 text-white", hover [ "bg-gray-600" ] ]
    in
    div [ class "az-commands absolute bottom-0 right-0 m-3 print:hidden" ]
        [ if conf.move && hasTables then
            span [ class "relative z-0 inline-flex shadow-sm rounded-md" ]
                [ button [ type_ "button", onClick FitContent, css [ "rounded-l-md rounded-r-md", buttonStyles, classic ] ] [ Icon.solid ArrowsExpand "" ]
                    |> Tooltip.t "Fit diagram to screen"
                ]

          else
            Html.none
        , if conf.update then
            span [ class "relative z-0 inline-flex shadow-sm rounded-md ml-2" ]
                [ button [ type_ "button", onClick (DetailsSidebarMsg DetailsSidebar.Toggle), css [ "rounded-l-md", buttonStyles, classic ] ] [ Icon.solid Menu "" ]
                    |> B.cond (conf.select && hasTables) Tooltip.t Tooltip.tl "List tables"
                , button [ type_ "button", onClick (AmlSidebarMsg AToggle), css [ "-ml-px rounded-r-md", buttonStyles, classic ] ] [ Icon.solid Pencil "" ]
                    |> B.cond (conf.move && hasTables) Tooltip.t Tooltip.tl "Update schema"
                ]

          else
            Html.none
        , if conf.move && hasTables then
            span [ class "relative z-0 inline-flex shadow-sm rounded-md ml-2" ]
                [ button [ type_ "button", onClick (CursorMode CursorMode.Select), css [ "rounded-l-md", buttonStyles, B.cond (cursorMode == CursorMode.Select) inverted classic ] ] [ Icon.solid CursorClick "" ]
                    |> Tooltip.t "Select tool"
                , button [ type_ "button", onClick (CursorMode CursorMode.Drag), css [ "-ml-px rounded-r-md", buttonStyles, B.cond (cursorMode == CursorMode.Drag) inverted classic ] ] [ Icon.solid Hand "" ]
                    |> Tooltip.t "Drag tool"
                ]

          else
            Html.none
        , if conf.move && hasTables then
            span [ class "relative z-0 inline-flex shadow-sm rounded-md ml-2" ]
                [ button [ type_ "button", onClick (Zoom (-canvasZoom / 10)), css [ "rounded-l-md", buttonStyles, classic ] ] [ Icon.solid Minus "" ]
                , Dropdown.dropdown { id = htmlId ++ "-zoom-level", direction = TopLeft, isOpen = openedDropdown == htmlId ++ "-zoom-level" }
                    (\m ->
                        button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup "true", css [ "-ml-px", buttonStyles, classic ] ]
                            [ text (String.fromInt (round (canvasZoom * 100)) ++ " %") ]
                    )
                    (\_ ->
                        div []
                            [ ContextMenu.btn "" (Zoom (Conf.canvas.zoom.min - canvasZoom)) [ text (String.fromFloat (Conf.canvas.zoom.min * 100) ++ " %") ]
                            , ContextMenu.btn "" (Zoom (0.25 - canvasZoom)) [ text "25%" ]
                            , ContextMenu.btn "" (Zoom (0.5 - canvasZoom)) [ text "50%" ]
                            , ContextMenu.btn "" (Zoom (0.8 - canvasZoom)) [ text "80%" ]
                            , ContextMenu.btn "" (Zoom (1 - canvasZoom)) [ text "100%" ]
                            , ContextMenu.btn "" (Zoom (1.2 - canvasZoom)) [ text "120%" ]
                            , ContextMenu.btn "" (Zoom (1.5 - canvasZoom)) [ text "150%" ]
                            , ContextMenu.btn "" (Zoom (2 - canvasZoom)) [ text "200%" ]
                            , ContextMenu.btn "" (Zoom (Conf.canvas.zoom.max - canvasZoom)) [ text (String.fromFloat (Conf.canvas.zoom.max * 100) ++ " %") ]
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
