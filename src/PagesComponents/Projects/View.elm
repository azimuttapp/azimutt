module PagesComponents.Projects.View exposing (viewProjects)

import Components.Atoms.Icon as Icon
import Css exposing (focus, hover)
import Css.Global as Global
import Html.Styled exposing (Html, a, button, div, h1, header, img, input, label, main_, nav, span, text)
import Html.Styled.Attributes exposing (alt, class, css, for, href, id, name, placeholder, src, tabindex, type_)
import Libs.Html.Styled.Attributes exposing (ariaControls, ariaCurrent, ariaExpanded, ariaHaspopup, ariaLabelledby, ariaOrientation, role)
import Tailwind.Breakpoints exposing (lg, sm)
import Tailwind.Utilities exposing (absolute, bg_indigo_500, bg_indigo_600, bg_indigo_700, bg_opacity_75, bg_white, block, border, border_4, border_b, border_dashed, border_gray_200, border_indigo_300, border_indigo_400, border_indigo_700, border_none, border_opacity_25, border_t, border_transparent, border_white, flex, flex_1, flex_shrink_0, font_bold, font_medium, globalStyles, h_10, h_16, h_8, h_96, hidden, inline_flex, inset_y_0, items_center, justify_between, justify_center, justify_end, leading_5, left_0, max_w_7xl, max_w_lg, max_w_xs, min_h_full, ml_10, ml_3, ml_4, ml_6, ml_auto, mt_2, mt_3, mx_auto, neg_mt_32, origin_top_right, outline_none, p_1, p_2, pb_12, pb_3, pb_32, pl_10, pl_3, placeholder_gray_500, pointer_events_none, pr_3, pt_2, pt_4, px_0, px_2, px_3, px_4, px_5, px_6, px_8, py_1, py_10, py_2, py_6, relative, right_0, ring_1, ring_2, ring_black, ring_offset_2, ring_offset_indigo_600, ring_opacity_5, ring_white, rounded_full, rounded_lg, rounded_md, shadow, shadow_lg, space_x_4, space_y_1, sr_only, text_3xl, text_base, text_gray_400, text_gray_700, text_gray_900, text_indigo_200, text_indigo_300, text_sm, text_white, w_10, w_48, w_8, w_full)


viewProjects : List (Html msg)
viewProjects =
    [ Global.global globalStyles
    , div [ css [ min_h_full ] ]
        [ div [ css [ bg_indigo_600, pb_32 ] ]
            [ nav [ css [ bg_indigo_600, border_b, border_indigo_300, border_opacity_25, lg [ border_none ] ] ]
                [ div [ css [ max_w_7xl, mx_auto, px_2, lg [ px_8 ], sm [ px_4 ] ] ]
                    [ div [ css [ relative, h_16, flex, items_center, justify_between, lg [ border_b, border_indigo_400, border_opacity_25 ] ] ]
                        [ div [ css [ px_2, flex, items_center, lg [ px_0 ] ] ]
                            [ div [ css [ flex_shrink_0 ] ]
                                [ img [ css [ block, h_8, w_8 ], src "https://tailwindui.com/img/logos/workflow-mark-indigo-300.svg", alt "Workflow" ] []
                                ]
                            , div [ css [ hidden, lg [ block, ml_10 ] ] ]
                                [ div [ css [ flex, space_x_4 ] ]
                                    [ {- Current: "bg-indigo-700 text-white", Default: "text-white hover:bg-indigo-500 hover:bg-opacity-75" -} a [ href "#", css [ bg_indigo_700, text_white, rounded_md, py_2, px_3, text_sm, font_medium ], ariaCurrent "page" ] [ text "Dashboard" ]
                                    , a [ href "#", css [ text_white, rounded_md, py_2, px_3, text_sm, font_medium, hover [ bg_indigo_500, bg_opacity_75 ] ] ] [ text "Team" ]
                                    , a [ href "#", css [ text_white, rounded_md, py_2, px_3, text_sm, font_medium, hover [ bg_indigo_500, bg_opacity_75 ] ] ] [ text "Projects" ]
                                    , a [ href "#", css [ text_white, rounded_md, py_2, px_3, text_sm, font_medium, hover [ bg_indigo_500, bg_opacity_75 ] ] ] [ text "Calendar" ]
                                    , a [ href "#", css [ text_white, rounded_md, py_2, px_3, text_sm, font_medium, hover [ bg_indigo_500, bg_opacity_75 ] ] ] [ text "Reports" ]
                                    ]
                                ]
                            ]
                        , div [ css [ flex_1, px_2, flex, justify_center, lg [ ml_6, justify_end ] ] ]
                            [ div [ css [ max_w_lg, w_full, lg [ max_w_xs ] ] ]
                                [ label [ for "search", css [ sr_only ] ] [ text "Search" ]
                                , div [ css [ relative, text_gray_400 ], class "focus-within:text-gray-600" ]
                                    [ div [ css [ pointer_events_none, absolute, inset_y_0, left_0, pl_3, flex, items_center ] ]
                                        [ Icon.search 5 []
                                        ]
                                    , input [ id "search", css [ block, w_full, bg_white, py_2, pl_10, pr_3, border, border_transparent, rounded_md, leading_5, text_gray_900, placeholder_gray_500, focus [ outline_none, ring_2, ring_offset_2, ring_offset_indigo_600, ring_white, border_white ], sm [ text_sm ] ], placeholder "Search", type_ "search", name "search" ] []
                                    ]
                                ]
                            ]
                        , div [ css [ flex, lg [ hidden ] ] ]
                            [ {- Mobile menu button -}
                              button [ type_ "button", css [ bg_indigo_600, p_2, rounded_md, inline_flex, items_center, justify_center, text_indigo_200, focus [ outline_none, ring_2, ring_offset_2, ring_offset_indigo_600, ring_white ], hover [ text_white, bg_indigo_500, bg_opacity_75 ] ], ariaControls "mobile-menu", ariaExpanded False ]
                                [ span [ css [ sr_only ] ] [ text "Open main menu" ]
                                , {- Menu open: "hidden", Menu closed: "block" -} Icon.menu 6 [ block ]
                                , {- Menu open: "block", Menu closed: "hidden" -} Icon.cross 6 [ hidden ]
                                ]
                            ]
                        , div [ css [ hidden, lg [ block, ml_4 ] ] ]
                            [ div [ css [ flex, items_center ] ]
                                [ button [ type_ "button", css [ bg_indigo_600, flex_shrink_0, rounded_full, p_1, text_indigo_200, focus [ outline_none, ring_2, ring_offset_2, ring_offset_indigo_600, ring_white ], hover [ text_white ] ] ]
                                    [ span [ css [ sr_only ] ] [ text "View notifications" ]
                                    , Icon.bell 6 []
                                    ]
                                , {- Profile dropdown -}
                                  div [ css [ ml_3, relative, flex_shrink_0 ] ]
                                    [ div []
                                        [ button [ type_ "button", css [ bg_indigo_600, rounded_full, flex, text_sm, text_white, focus [ outline_none, ring_2, ring_offset_2, ring_offset_indigo_600, ring_white ] ], id "user-menu-button", ariaExpanded False, ariaHaspopup True ]
                                            [ span [ css [ sr_only ] ] [ text "Open user menu" ]
                                            , img [ css [ rounded_full, h_8, w_8 ], src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
                                            ]
                                        ]
                                    , {-
                                         Dropdown menu, show/hide based on menu state.

                                         Entering: "transition ease-out duration-100"
                                           From: "transform opacity-0 scale-95"
                                           To: "transform opacity-100 scale-100"
                                         Leaving: "transition ease-in duration-75"
                                           From: "transform opacity-100 scale-100"
                                           To: "transform opacity-0 scale-95"
                                      -}
                                      div [ css [ origin_top_right, absolute, right_0, mt_2, w_48, rounded_md, shadow_lg, py_1, bg_white, ring_1, ring_black, ring_opacity_5, focus [ outline_none ] ], role "menu", ariaOrientation "vertical", ariaLabelledby "user-menu-button", tabindex -1 ]
                                        [ {- Active: "bg-gray-100", Not Active: "" -} a [ href "#", css [ block, py_2, px_4, text_sm, text_gray_700 ], role "menuitem", tabindex -1, id "user-menu-item-0" ] [ text "Your Profile" ]
                                        , a [ href "#", css [ block, py_2, px_4, text_sm, text_gray_700 ], role "menuitem", tabindex -1, id "user-menu-item-1" ] [ text "Settings" ]
                                        , a [ href "#", css [ block, py_2, px_4, text_sm, text_gray_700 ], role "menuitem", tabindex -1, id "user-menu-item-2" ] [ text "Sign out" ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                , {- Mobile menu, show/hide based on menu state. -}
                  div [ css [ lg [ hidden ] ], id "mobile-menu" ]
                    [ div [ css [ px_2, pt_2, pb_3, space_y_1 ] ]
                        [ {- Current: "bg-indigo-700 text-white", Default: "text-white hover:bg-indigo-500 hover:bg-opacity-75" -} a [ href "#", css [ bg_indigo_700, text_white, block, rounded_md, py_2, px_3, text_base, font_medium ], ariaCurrent "page" ] [ text "Dashboard" ]
                        , a [ href "#", css [ text_white, block, rounded_md, py_2, px_3, text_base, font_medium, Css.hover [ bg_indigo_500, bg_opacity_75 ] ] ] [ text "Team" ]
                        , a [ href "#", css [ text_white, block, rounded_md, py_2, px_3, text_base, font_medium, Css.hover [ bg_indigo_500, bg_opacity_75 ] ] ] [ text "Projects" ]
                        , a [ href "#", css [ text_white, block, rounded_md, py_2, px_3, text_base, font_medium, Css.hover [ bg_indigo_500, bg_opacity_75 ] ] ] [ text "Calendar" ]
                        , a [ href "#", css [ text_white, block, rounded_md, py_2, px_3, text_base, font_medium, Css.hover [ bg_indigo_500, bg_opacity_75 ] ] ] [ text "Reports" ]
                        ]
                    , div [ css [ pt_4, pb_3, border_t, border_indigo_700 ] ]
                        [ div [ css [ px_5, flex, items_center ] ]
                            [ div [ css [ flex_shrink_0 ] ]
                                [ img [ css [ rounded_full, h_10, w_10 ], src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
                                ]
                            , div [ css [ ml_3 ] ]
                                [ div [ css [ text_base, font_medium, text_white ] ] [ text "Tom Cook" ]
                                , div [ css [ text_sm, font_medium, text_indigo_300 ] ] [ text "tom@example.com" ]
                                ]
                            , button [ type_ "button", css [ ml_auto, bg_indigo_600, flex_shrink_0, rounded_full, p_1, text_indigo_200, Css.focus [ outline_none, ring_2, ring_offset_2, ring_offset_indigo_600, ring_white ], Css.hover [ text_white ] ] ]
                                [ span [ css [ sr_only ] ] [ text "View notifications" ]
                                , Icon.bell 6 []
                                ]
                            ]
                        , div [ css [ mt_3, px_2, space_y_1 ] ]
                            [ a [ href "#", css [ block, rounded_md, py_2, px_3, text_base, font_medium, text_white, Css.hover [ bg_indigo_500, bg_opacity_75 ] ] ] [ text "Your Profile" ]
                            , a [ href "#", css [ block, rounded_md, py_2, px_3, text_base, font_medium, text_white, Css.hover [ bg_indigo_500, bg_opacity_75 ] ] ] [ text "Settings" ]
                            , a [ href "#", css [ block, rounded_md, py_2, px_3, text_base, font_medium, text_white, Css.hover [ bg_indigo_500, bg_opacity_75 ] ] ] [ text "Sign out" ]
                            ]
                        ]
                    ]
                ]
            , header [ css [ py_10 ] ]
                [ div [ css [ max_w_7xl, mx_auto, px_4, lg [ px_8 ], sm [ px_6 ] ] ]
                    [ h1 [ css [ text_3xl, font_bold, text_white ] ] [ text "Dashboard" ]
                    ]
                ]
            ]
        , main_ [ css [ neg_mt_32 ] ]
            [ div [ css [ max_w_7xl, mx_auto, pb_12, px_4, lg [ px_8 ], sm [ px_6 ] ] ]
                [ {- Replace with your content -}
                  div [ css [ bg_white, rounded_lg, shadow, px_5, py_6, sm [ px_6 ] ] ]
                    [ div [ css [ h_96, border_4, border_dashed, border_gray_200, rounded_lg ] ] []
                    ]

                {- /End replace -}
                ]
            ]
        ]
    ]
