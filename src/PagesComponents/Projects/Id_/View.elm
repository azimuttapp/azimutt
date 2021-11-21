module PagesComponents.Projects.Id_.View exposing (viewProject)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Css exposing (focus, hover)
import Css.Global as Global
import Gen.Route as Route
import Html.Styled exposing (Html, a, button, div, img, main_, nav, span, text)
import Html.Styled.Attributes exposing (alt, css, height, href, id, src, tabindex, type_, width)
import Libs.Html.Styled.Attributes exposing (ariaControls, ariaCurrent, ariaExpanded, ariaHaspopup, ariaLabelledby, ariaOrientation, role)
import Tailwind.Breakpoints exposing (lg, sm)
import Tailwind.Utilities exposing (absolute, bg_gray_100, bg_gray_50, bg_indigo_50, bg_white, block, border_4, border_b_2, border_dashed, border_gray_200, border_gray_300, border_indigo_500, border_l_4, border_t, border_transparent, flex, flex_shrink_0, font_medium, globalStyles, h_10, h_16, h_8, h_96, h_full, hidden, inline_flex, items_center, justify_between, justify_center, ml_3, ml_6, ml_auto, mt_2, mt_3, mx_auto, neg_mr_2, neg_my_px, origin_top_right, outline_none, p_1, p_2, pb_3, pl_3, pr_4, pt_1, pt_2, pt_4, px_1, px_4, px_6, px_8, py_1, py_2, relative, right_0, ring_1, ring_2, ring_black, ring_indigo_500, ring_offset_2, ring_opacity_5, rounded_full, rounded_lg, rounded_md, shadow_lg, shadow_sm, space_x_8, space_y_1, sr_only, text_base, text_gray_400, text_gray_500, text_gray_600, text_gray_700, text_gray_800, text_gray_900, text_indigo_700, text_sm, w_10, w_48, w_8, w_auto)


viewProject : List (Html msg)
viewProject =
    [ Global.global globalStyles
    , Global.global [ Global.selector "html" [ h_full, bg_gray_100 ], Global.selector "body" [ h_full ] ]
    , nav [ css [ bg_white, shadow_sm ] ]
        [ div [ css [ mx_auto, px_4, lg [ px_8 ], sm [ px_6 ] ] ]
            [ div [ css [ flex, justify_between, h_16 ] ]
                [ div [ css [ flex ] ]
                    [ a [ href (Route.toHref Route.Projects), css [ flex_shrink_0, flex, items_center ] ]
                        [ img [ css [ block, h_8, w_auto, lg [ hidden ] ], src "https://tailwindui.com/img/logos/workflow-mark-indigo-600.svg", alt "Workflow", width 35, height 32 ] []
                        , img [ css [ hidden, h_8, w_auto, lg [ block ] ], src "https://tailwindui.com/img/logos/workflow-logo-indigo-600-mark-gray-800-text.svg", alt "Workflow", width 143, height 32 ] []
                        ]
                    , div [ css [ hidden, sm [ neg_my_px, ml_6, flex, space_x_8 ] ] ]
                        [ {- Current: "border-indigo-500 text-gray-900", Default: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300" -} a [ href "#", css [ border_indigo_500, text_gray_900, inline_flex, items_center, px_1, pt_1, border_b_2, text_sm, font_medium ], ariaCurrent "page" ] [ text "Dashboard" ]
                        , a [ href "#", css [ border_transparent, text_gray_500, inline_flex, items_center, px_1, pt_1, border_b_2, text_sm, font_medium, hover [ text_gray_700, border_gray_300 ] ] ] [ text "Team" ]
                        , a [ href "#", css [ border_transparent, text_gray_500, inline_flex, items_center, px_1, pt_1, border_b_2, text_sm, font_medium, hover [ text_gray_700, border_gray_300 ] ] ] [ text "Projects" ]
                        , a [ href "#", css [ border_transparent, text_gray_500, inline_flex, items_center, px_1, pt_1, border_b_2, text_sm, font_medium, hover [ text_gray_700, border_gray_300 ] ] ] [ text "Calendar" ]
                        ]
                    ]
                , div [ css [ hidden, sm [ ml_6, flex, items_center ] ] ]
                    [ button [ type_ "button", css [ bg_white, p_1, rounded_full, text_gray_400, focus [ outline_none, ring_2, ring_offset_2, ring_indigo_500 ], hover [ text_gray_500 ] ] ]
                        [ span [ css [ sr_only ] ] [ text "View notifications" ]
                        , Icon.outline Bell []
                        ]
                    , {- Profile dropdown -}
                      div [ css [ ml_3, relative ] ]
                        [ div []
                            [ button [ type_ "button", css [ bg_white, flex, text_sm, rounded_full, focus [ outline_none, ring_2, ring_offset_2, ring_indigo_500 ] ], id "user-menu-button", ariaExpanded False, ariaHaspopup True ]
                                [ span [ css [ sr_only ] ] [ text "Open user menu" ]
                                , img [ css [ h_8, w_8, rounded_full ], src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "", width 32, height 32 ] []
                                ]
                            ]
                        , {-
                             Dropdown menu, show/hide based on menu state.

                             Entering: "transition ease-out duration-200"
                               From: "transform opacity-0 scale-95"
                               To: "transform opacity-100 scale-100"
                             Leaving: "transition ease-in duration-75"
                               From: "transform opacity-100 scale-100"
                               To: "transform opacity-0 scale-95"
                          -}
                          div [ css [ origin_top_right, absolute, right_0, mt_2, w_48, rounded_md, shadow_lg, py_1, bg_white, ring_1, ring_black, ring_opacity_5, focus [ outline_none ] ], role "menu", ariaOrientation "vertical", ariaLabelledby "user-menu-button", tabindex -1 ]
                            [ {- Active: "bg-gray-100", Not Active: "" -} a [ href "#", css [ block, px_4, py_2, text_sm, text_gray_700 ], role "menuitem", tabindex -1, id "user-menu-item-0" ] [ text "Your Profile" ]
                            , a [ href "#", css [ block, px_4, py_2, text_sm, text_gray_700 ], role "menuitem", tabindex -1, id "user-menu-item-1" ] [ text "Settings" ]
                            , a [ href "#", css [ block, px_4, py_2, text_sm, text_gray_700 ], role "menuitem", tabindex -1, id "user-menu-item-2" ] [ text "Sign out" ]
                            ]
                        ]
                    ]
                , div [ css [ neg_mr_2, flex, items_center, sm [ hidden ] ] ]
                    [ {- Mobile menu button -}
                      button [ type_ "button", css [ bg_white, inline_flex, items_center, justify_center, p_2, rounded_md, text_gray_400, focus [ outline_none, ring_2, ring_offset_2, ring_indigo_500 ], hover [ text_gray_500, bg_gray_100 ] ], ariaControls "mobile-menu", ariaExpanded False ]
                        [ span [ css [ sr_only ] ] [ text "Open main menu" ]
                        , {- Menu open: "hidden", Menu closed: "block" -} Icon.outline Menu [ block ]
                        , {- Menu open: "block", Menu closed: "hidden" -} Icon.outline X [ hidden ]
                        ]
                    ]
                ]
            ]
        , {- Mobile menu, show/hide based on menu state. -}
          div [ css [ sm [ hidden ] ], id "mobile-menu" ]
            [ div [ css [ pt_2, pb_3, space_y_1 ] ]
                [ {- Current: "bg-indigo-50 border-indigo-500 text-indigo-700", Default: "border-transparent text-gray-600 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-800" -} a [ href "#", css [ bg_indigo_50, border_indigo_500, text_indigo_700, block, pl_3, pr_4, py_2, border_l_4, text_base, font_medium ], ariaCurrent "page" ] [ text "Dashboard" ]
                , a [ href "#", css [ border_transparent, text_gray_600, block, pl_3, pr_4, py_2, border_l_4, text_base, font_medium, hover [ bg_gray_50, border_gray_300, text_gray_800 ] ] ] [ text "Team" ]
                , a [ href "#", css [ border_transparent, text_gray_600, block, pl_3, pr_4, py_2, border_l_4, text_base, font_medium, hover [ bg_gray_50, border_gray_300, text_gray_800 ] ] ] [ text "Projects" ]
                , a [ href "#", css [ border_transparent, text_gray_600, block, pl_3, pr_4, py_2, border_l_4, text_base, font_medium, hover [ bg_gray_50, border_gray_300, text_gray_800 ] ] ] [ text "Calendar" ]
                ]
            , div [ css [ pt_4, pb_3, border_t, border_gray_200 ] ]
                [ div [ css [ flex, items_center, px_4 ] ]
                    [ div [ css [ flex_shrink_0 ] ]
                        [ img [ css [ h_10, w_10, rounded_full ], src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "", width 40, height 40 ] []
                        ]
                    , div [ css [ ml_3 ] ]
                        [ div [ css [ text_base, font_medium, text_gray_800 ] ] [ text "Tom Cook" ]
                        , div [ css [ text_sm, font_medium, text_gray_500 ] ] [ text "tom@example.com" ]
                        ]
                    , button [ type_ "button", css [ ml_auto, bg_white, flex_shrink_0, p_1, rounded_full, text_gray_400, focus [ outline_none, ring_2, ring_offset_2, ring_indigo_500 ], hover [ text_gray_500 ] ] ]
                        [ span [ css [ sr_only ] ] [ text "View notifications" ]
                        , Icon.outline Bell []
                        ]
                    ]
                , div [ css [ mt_3, space_y_1 ] ]
                    [ a [ href "#", css [ block, px_4, py_2, text_base, font_medium, text_gray_500, hover [ text_gray_800, bg_gray_100 ] ] ] [ text "Your Profile" ]
                    , a [ href "#", css [ block, px_4, py_2, text_base, font_medium, text_gray_500, hover [ text_gray_800, bg_gray_100 ] ] ] [ text "Settings" ]
                    , a [ href "#", css [ block, px_4, py_2, text_base, font_medium, text_gray_500, hover [ text_gray_800, bg_gray_100 ] ] ] [ text "Sign out" ]
                    ]
                ]
            ]
        ]
    , main_ [ css [ border_4, border_dashed, border_gray_200, rounded_lg, h_96 ] ]
        [{- Replace with your content -}]
    ]
