module PagesComponents.Projects.Id_.View exposing (viewProject)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Slices.NotFound as NotFound
import Conf exposing (constants)
import Css
import Css.Global as Global
import Gen.Route as Route
import Html.Styled exposing (Html, a, button, div, img, input, label, main_, nav, span, text)
import Html.Styled.Attributes exposing (alt, css, for, href, id, name, placeholder, src, tabindex, type_)
import Libs.Html.Styled.Attributes exposing (ariaControls, ariaExpanded, ariaHaspopup, ariaLabelledby, ariaOrientation, role)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColorLevel(..), TwColorPosition(..))
import Models.Project exposing (Project)
import PagesComponents.Projects.Id_.Models exposing (Model)
import Shared exposing (StoredProjects(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw exposing (bg_gray_100, globalStyles, h_full)


viewProject : Shared.Model -> Model -> List (Html msg)
viewProject shared model =
    [ Global.global globalStyles
    , Global.global [ Global.selector "html" [ h_full, bg_gray_100 ], Global.selector "body" [ h_full ] ]
    , case shared.projects of
        Loading ->
            viewLoader shared.theme

        Loaded projects ->
            projects |> L.find (\p -> p.id == model.projectId) |> M.mapOrElse (viewApp shared.theme) (viewNotFound shared.theme)
    ]


viewLoader : Theme -> Html msg
viewLoader theme =
    div [ css [ Tw.flex, Tw.justify_center, Tw.items_center, Tw.h_screen ] ]
        [ div [ css [ Tw.animate_spin, Tw.rounded_full, Tw.h_32, Tw.w_32, Tw.border_t_2, Tw.border_b_2, TwColor.render Border theme.color L500 ] ] []
        ]


viewNotFound : Theme -> Html msg
viewNotFound theme =
    NotFound.simple theme
        { brand =
            { img = { src = "/logo.png", alt = "Azimutt" }
            , link = { url = Route.toHref Route.Home_, text = "Azimutt" }
            }
        , header = "404 error"
        , title = "Project not found."
        , message = "Sorry, we couldn't find the project you’re looking for."
        , link = { url = Route.toHref Route.Projects, text = "Go back to dashboard" }
        , footer =
            [ { url = constants.azimuttGithub ++ "/discussions", text = "Contact Support" }
            , { url = constants.azimuttTwitter, text = "Twitter" }
            , { url = Route.toHref Route.Blog, text = "Blog" }
            ]
        }


viewApp : Theme -> Project -> Html msg
viewApp theme project =
    div []
        [ viewNavbar theme project
        , viewContent theme project
        ]


viewNavbar : Theme -> Project -> Html msg
viewNavbar _ _ =
    nav [ css [ Tw.bg_gray_800 ] ]
        [ div [ css [ Tw.max_w_7xl, Tw.mx_auto, Tw.px_2, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_4 ] ] ]
            [ div [ css [ Tw.relative, Tw.flex, Tw.items_center, Tw.justify_between, Tw.h_16 ] ]
                [ div [ css [ Tw.flex, Tw.items_center, Tw.px_2, Bp.lg [ Tw.px_0 ] ] ]
                    [ div [ css [ Tw.flex_shrink_0 ] ]
                        [ img [ css [ Tw.block, Tw.h_8, Tw.w_auto, Bp.lg [ Tw.hidden ] ], src "https://tailwindui.com/img/logos/workflow-mark-indigo-500.svg", alt "Workflow" ] []
                        , img [ css [ Tw.hidden, Tw.h_8, Tw.w_auto, Bp.lg [ Tw.block ] ], src "https://tailwindui.com/img/logos/workflow-logo-indigo-500-mark-white-text.svg", alt "Workflow" ] []
                        ]
                    , div [ css [ Tw.hidden, Bp.lg [ Tw.block, Tw.ml_6 ] ] ]
                        [ div [ css [ Tw.flex, Tw.space_x_4 ] ]
                            [ {- Current: "bg-gray-900 text-white", Default: "text-gray-300 hover:bg-gray-700 hover:text-white" -}
                              a [ href "#", css [ Tw.bg_gray_900, Tw.text_white, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.text_sm, Tw.font_medium ] ]
                                [ text "Dashboard" ]
                            , a [ href "#", css [ Tw.text_gray_300, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.text_sm, Tw.font_medium, Css.hover [ Tw.bg_gray_700, Tw.text_white ] ] ]
                                [ text "Team" ]
                            , a [ href "#", css [ Tw.text_gray_300, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.text_sm, Tw.font_medium, Css.hover [ Tw.bg_gray_700, Tw.text_white ] ] ]
                                [ text "Projects" ]
                            , a [ href "#", css [ Tw.text_gray_300, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.text_sm, Tw.font_medium, Css.hover [ Tw.bg_gray_700, Tw.text_white ] ] ]
                                [ text "Calendar" ]
                            ]
                        ]
                    ]
                , div [ css [ Tw.flex_1, Tw.flex, Tw.justify_center, Tw.px_2, Bp.lg [ Tw.ml_6, Tw.justify_end ] ] ]
                    [ div [ css [ Tw.max_w_lg, Tw.w_full, Bp.lg [ Tw.max_w_xs ] ] ]
                        [ label [ for "search", css [ Tw.sr_only ] ] [ text "Search" ]
                        , div [ css [ Tw.relative ] ]
                            [ div [ css [ Tw.absolute, Tw.inset_y_0, Tw.left_0, Tw.pl_3, Tw.flex, Tw.items_center, Tw.pointer_events_none ] ]
                                [ Icon.solid Search [ Tw.text_gray_400 ]
                                ]
                            , input [ id "search", name "search", css [ Tw.block, Tw.w_full, Tw.pl_10, Tw.pr_3, Tw.py_2, Tw.border, Tw.border_transparent, Tw.rounded_md, Tw.leading_5, Tw.bg_gray_700, Tw.text_gray_300, Tw.placeholder_gray_400, Css.focus [ Tw.outline_none, Tw.bg_white, Tw.border_white, Tw.ring_white, Tw.text_gray_900 ], Bp.sm [ Tw.text_sm ] ], placeholder "Search", type_ "search" ] []
                            ]
                        ]
                    ]
                , div [ css [ Tw.flex, Bp.lg [ Tw.hidden ] ] ]
                    [ {- Mobile menu button -}
                      button [ type_ "button", css [ Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.p_2, Tw.rounded_md, Tw.text_gray_400, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_inset, Tw.ring_white ], Css.hover [ Tw.text_white, Tw.bg_gray_700 ] ], ariaControls "mobile-menu", ariaExpanded False ]
                        [ span [ css [ Tw.sr_only ] ] [ text "Open main menu" ]
                        , {- Menu open: "hidden", Menu closed: "block" -} Icon.outline Menu [ Tw.block ]
                        , {- Menu open: "block", Menu closed: "hidden" -} Icon.outline X [ Tw.hidden ]
                        ]
                    ]
                , div [ css [ Tw.hidden, Bp.lg [ Tw.block, Tw.ml_4 ] ] ]
                    [ div [ css [ Tw.flex, Tw.items_center ] ]
                        [ button [ type_ "button", css [ Tw.flex_shrink_0, Tw.bg_gray_800, Tw.p_1, Tw.rounded_full, Tw.text_gray_400, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, Tw.ring_offset_gray_800, Tw.ring_white ], Css.hover [ Tw.text_white ] ] ]
                            [ span [ css [ Tw.sr_only ] ] [ text "View notifications" ]
                            , {- Heroicon name: outline/bell -} Icon.outline Bell []
                            ]
                        , {- Profile dropdown -}
                          div [ css [ Tw.ml_4, Tw.relative, Tw.flex_shrink_0 ] ]
                            [ div []
                                [ button [ type_ "button", css [ Tw.bg_gray_800, Tw.rounded_full, Tw.flex, Tw.text_sm, Tw.text_white, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, Tw.ring_offset_gray_800, Tw.ring_white ] ], id "user-menu-button", ariaExpanded False, ariaHaspopup True ]
                                    [ span [ css [ Tw.sr_only ] ] [ text "Open user menu" ]
                                    , img [ css [ Tw.h_8, Tw.w_8, Tw.rounded_full ], src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
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
                              div [ css [ Tw.origin_top_right, Tw.absolute, Tw.right_0, Tw.mt_2, Tw.w_48, Tw.rounded_md, Tw.shadow_lg, Tw.py_1, Tw.bg_white, Tw.ring_1, Tw.ring_black, Tw.ring_opacity_5, Css.focus [ Tw.outline_none ] ], role "menu", ariaOrientation "vertical", ariaLabelledby "user-menu-button", tabindex -1 ]
                                [ {- Active: "bg-gray-100", Not Active: "" -} a [ href "#", css [ Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Tw.text_gray_700 ], role "menuitem", tabindex -1, id "user-menu-item-0" ] [ text "Your Profile" ]
                                , a [ href "#", css [ Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Tw.text_gray_700 ], role "menuitem", tabindex -1, id "user-menu-item-1" ] [ text "Settings" ]
                                , a [ href "#", css [ Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Tw.text_gray_700 ], role "menuitem", tabindex -1, id "user-menu-item-2" ] [ text "Sign out" ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        , {- Mobile menu, show/hide based on menu state. -}
          div [ css [ Bp.lg [ Tw.hidden ] ], id "mobile-menu" ]
            [ div [ css [ Tw.px_2, Tw.pt_2, Tw.pb_3, Tw.space_y_1 ] ]
                [ {- Current: "bg-gray-900 text-white", Default: "text-gray-300 hover:bg-gray-700 hover:text-white" -}
                  a [ href "#", css [ Tw.bg_gray_900, Tw.text_white, Tw.block, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.text_base, Tw.font_medium ] ]
                    [ text "Dashboard" ]
                , a [ href "#", css [ Tw.text_gray_300, Tw.block, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.text_base, Tw.font_medium, Css.hover [ Tw.bg_gray_700, Tw.text_white ] ] ]
                    [ text "Team" ]
                , a [ href "#", css [ Tw.text_gray_300, Tw.block, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.text_base, Tw.font_medium, Css.hover [ Tw.bg_gray_700, Tw.text_white ] ] ]
                    [ text "Projects" ]
                , a [ href "#", css [ Tw.text_gray_300, Tw.block, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.text_base, Tw.font_medium, Css.hover [ Tw.bg_gray_700, Tw.text_white ] ] ]
                    [ text "Calendar" ]
                ]
            , div [ css [ Tw.pt_4, Tw.pb_3, Tw.border_t, Tw.border_gray_700 ] ]
                [ div [ css [ Tw.flex, Tw.items_center, Tw.px_5 ] ]
                    [ div [ css [ Tw.flex_shrink_0 ] ]
                        [ img [ css [ Tw.h_10, Tw.w_10, Tw.rounded_full ], src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
                        ]
                    , div [ css [ Tw.ml_3 ] ]
                        [ div [ css [ Tw.text_base, Tw.font_medium, Tw.text_white ] ]
                            [ text "Tom Cook" ]
                        , div [ css [ Tw.text_sm, Tw.font_medium, Tw.text_gray_400 ] ]
                            [ text "tom@example.com" ]
                        ]
                    , button [ type_ "button", css [ Tw.ml_auto, Tw.flex_shrink_0, Tw.bg_gray_800, Tw.p_1, Tw.rounded_full, Tw.text_gray_400, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, Tw.ring_offset_gray_800, Tw.ring_white ], Css.hover [ Tw.text_white ] ] ]
                        [ span [ css [ Tw.sr_only ] ] [ text "View notifications" ]
                        , Icon.outline Bell []
                        ]
                    ]
                , div [ css [ Tw.mt_3, Tw.px_2, Tw.space_y_1 ] ]
                    [ a [ href "#", css [ Tw.block, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.text_base, Tw.font_medium, Tw.text_gray_400, Css.hover [ Tw.text_white, Tw.bg_gray_700 ] ] ] [ text "Your Profile" ]
                    , a [ href "#", css [ Tw.block, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.text_base, Tw.font_medium, Tw.text_gray_400, Css.hover [ Tw.text_white, Tw.bg_gray_700 ] ] ] [ text "Settings" ]
                    , a [ href "#", css [ Tw.block, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.text_base, Tw.font_medium, Tw.text_gray_400, Css.hover [ Tw.text_white, Tw.bg_gray_700 ] ] ] [ text "Sign out" ]
                    ]
                ]
            ]
        ]


viewContent : Theme -> Project -> Html msg
viewContent _ _ =
    main_ [ css [ Tw.border_4, Tw.border_dashed, Tw.border_gray_200, Tw.rounded_lg, Tw.h_96 ] ]
        [{- Replace with your content -}]
