module PagesComponents.Projects.Id_.Views.Commands exposing (viewCommands)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Components.Molecules.Tooltip as Tooltip
import Conf
import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class, id, type_)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Tailwind exposing (TwClass, batch, focus, hover)
import PagesComponents.Projects.Id_.Models exposing (CursorMode(..), Msg(..))


viewCommands : CursorMode -> ZoomLevel -> Bool -> HtmlId -> HtmlId -> Html Msg
viewCommands cursorMode canvasZoom hide htmlId openedDropdown =
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
    div [ class ("tw-commands absolute bottom-0 right-0 m-3" ++ B.cond hide " hidden" "") ]
        [ span [ class "relative z-0 inline-flex shadow-sm rounded-md" ]
            [ button [ type_ "button", onClick FitContent, css [ "rounded-l-md rounded-r-md", buttonStyles, classic ] ]
                [ Icon.solid ArrowsExpand "" ]
                |> Tooltip.t "Fit content in view"
            ]
        , span [ class "relative z-0 inline-flex shadow-sm rounded-md ml-2" ]
            [ button [ type_ "button", onClick (CursorMode CursorSelect), css [ "rounded-l-md", buttonStyles, B.cond (cursorMode == CursorSelect) inverted classic ] ] [ Icon.solid CursorClick "" ] |> Tooltip.t "Select tool"
            , button [ type_ "button", onClick (CursorMode CursorDrag), css [ "-ml-px rounded-r-md", buttonStyles, B.cond (cursorMode == CursorDrag) inverted classic ] ] [ Icon.solid Hand "" ] |> Tooltip.t "Drag tool"
            ]
        , span [ class "relative z-0 inline-flex shadow-sm rounded-md ml-2" ]
            [ button [ type_ "button", onClick (Zoom (-canvasZoom / 10)), css [ "rounded-l-md", buttonStyles, classic ] ] [ Icon.solid Minus "" ]
            , Dropdown.dropdown { id = htmlId ++ "-zoom-level", direction = TopLeft, isOpen = openedDropdown == htmlId ++ "-zoom-level" }
                (\m ->
                    button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup True, css [ "-ml-px", buttonStyles, classic ] ]
                        [ text (String.fromInt (round (canvasZoom * 100)) ++ " %") ]
                )
                (\_ ->
                    div []
                        [ Dropdown.btn "" (Zoom (Conf.canvas.zoom.min - canvasZoom)) [ text (String.fromFloat (Conf.canvas.zoom.min * 100) ++ " %") ]
                        , Dropdown.btn "" (Zoom (0.25 - canvasZoom)) [ text "25%" ]
                        , Dropdown.btn "" (Zoom (0.5 - canvasZoom)) [ text "50%" ]
                        , Dropdown.btn "" (Zoom (1 - canvasZoom)) [ text "100%" ]
                        , Dropdown.btn "" (Zoom (1.5 - canvasZoom)) [ text "150%" ]
                        , Dropdown.btn "" (Zoom (2 - canvasZoom)) [ text "200%" ]
                        , Dropdown.btn "" (Zoom (Conf.canvas.zoom.max - canvasZoom)) [ text (String.fromFloat (Conf.canvas.zoom.max * 100) ++ " %") ]
                        ]
                )
            , button [ type_ "button", onClick (Zoom (canvasZoom / 10)), css [ "-ml-px rounded-r-md", buttonStyles, classic ] ] [ Icon.solid Plus "" ]
            ]
        ]
