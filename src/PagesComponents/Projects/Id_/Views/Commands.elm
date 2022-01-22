module PagesComponents.Projects.Id_.Views.Commands exposing (viewCommands)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Components.Molecules.Tooltip as Tooltip
import Conf
import Css
import Html.Styled exposing (Html, button, div, span, text)
import Html.Styled.Attributes exposing (class, css, id, type_)
import Html.Styled.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHaspopup)
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import PagesComponents.Projects.Id_.Models exposing (CursorMode(..), Msg(..))
import Tailwind.Utilities as Tw


viewCommands : Theme -> CursorMode -> ZoomLevel -> HtmlId -> HtmlId -> Html Msg
viewCommands theme cursorMode canvasZoom htmlId openedDropdown =
    let
        buttonStyles : Css.Style
        buttonStyles =
            Css.batch [ Tw.relative, Tw.inline_flex, Tw.items_center, Tw.p_2, Tw.border, Tw.border_gray_300, Tw.text_sm, Tw.font_medium, Css.focus [ Tw.z_10, Tw.outline_none, Tw.ring_1, Color.ring theme.color 500, Color.border theme.color 500 ] ]

        classic : Css.Style
        classic =
            Css.batch [ Tw.bg_white, Tw.text_gray_700, Css.hover [ Tw.bg_gray_50 ] ]

        inverted : Css.Style
        inverted =
            Css.batch [ Tw.bg_gray_700, Tw.text_white, Css.hover [ Tw.bg_gray_600 ] ]
    in
    div [ class "tw-commands", css [ Tw.absolute, Tw.bottom_0, Tw.right_0, Tw.p_3 ] ]
        [ span [ css [ Tw.relative, Tw.z_0, Tw.inline_flex, Tw.shadow_sm, Tw.rounded_md ] ]
            [ button [ type_ "button", onClick FitContent, css [ Tw.rounded_l_md, Tw.rounded_r_md, buttonStyles, classic ] ] [ Icon.solid ArrowsExpand [] ] |> Tooltip.t "Fit content in view"
            ]
        , span [ css [ Tw.relative, Tw.z_0, Tw.inline_flex, Tw.shadow_sm, Tw.rounded_md, Tw.ml_2 ] ]
            [ button [ type_ "button", onClick (CursorMode CursorSelect), css [ Tw.rounded_l_md, buttonStyles, B.cond (cursorMode == CursorSelect) inverted classic ] ] [ Icon.solid CursorClick [] ] |> Tooltip.t "Select tool"
            , button [ type_ "button", onClick (CursorMode CursorDrag), css [ Tw.neg_ml_px, Tw.rounded_r_md, buttonStyles, B.cond (cursorMode == CursorDrag) inverted classic ] ] [ Icon.solid Hand [] ] |> Tooltip.t "Drag tool"
            ]
        , span [ css [ Tw.relative, Tw.z_0, Tw.inline_flex, Tw.shadow_sm, Tw.rounded_md, Tw.ml_2 ] ]
            [ button [ type_ "button", onClick (Zoom (-canvasZoom / 10)), css [ Tw.rounded_l_md, buttonStyles, classic ] ] [ Icon.solid Minus [] ]
            , Dropdown.dropdown { id = htmlId ++ "-zoom-level", direction = TopLeft, isOpen = openedDropdown == htmlId ++ "-zoom-level" }
                (\m ->
                    button [ type_ "button", id m.id, onClick (DropdownToggle m.id), ariaExpanded False, ariaHaspopup True, css [ Tw.neg_ml_px, buttonStyles, classic ] ]
                        [ text (String.fromInt (round (canvasZoom * 100)) ++ " %") ]
                )
                (\_ ->
                    div []
                        [ Dropdown.btn [] (Zoom (Conf.canvas.zoom.min - canvasZoom)) [ text (String.fromFloat (Conf.canvas.zoom.min * 100) ++ " %") ]
                        , Dropdown.btn [] (Zoom (0.25 - canvasZoom)) [ text "25%" ]
                        , Dropdown.btn [] (Zoom (0.5 - canvasZoom)) [ text "50%" ]
                        , Dropdown.btn [] (Zoom (1 - canvasZoom)) [ text "100%" ]
                        , Dropdown.btn [] (Zoom (1.5 - canvasZoom)) [ text "150%" ]
                        , Dropdown.btn [] (Zoom (2 - canvasZoom)) [ text "200%" ]
                        , Dropdown.btn [] (Zoom (Conf.canvas.zoom.max - canvasZoom)) [ text (String.fromFloat (Conf.canvas.zoom.max * 100) ++ " %") ]
                        ]
                )
            , button [ type_ "button", onClick (Zoom (canvasZoom / 10)), css [ Tw.neg_ml_px, Tw.rounded_r_md, buttonStyles, classic ] ] [ Icon.solid Plus [] ]
            ]
        ]
