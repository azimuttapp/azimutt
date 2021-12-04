module PagesComponents.Projects.Id_.Views.Navbar exposing (viewNavbar)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Css exposing (Style)
import Gen.Route as Route
import Html.Styled exposing (Html, a, button, div, img, input, label, nav, span, text)
import Html.Styled.Attributes exposing (alt, css, for, height, href, id, name, placeholder, src, tabindex, type_, width)
import Libs.Bool as B
import Libs.Html.Styled.Attributes exposing (ariaControls, ariaExpanded, ariaHaspopup, role)
import Libs.Models exposing (Link)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Libs.Tailwind.Utilities as Tu
import Models.Project exposing (Project)
import PagesComponents.Projects.Id_.Models exposing (NavbarModel)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


viewNavbar : Theme -> List Project -> Project -> NavbarModel -> Html msg
viewNavbar theme _ _ model =
    let
        menuLinks : List Link
        menuLinks =
            [ { url = "#", text = "Dashboard" }, { url = "#", text = "Team" }, { url = "#", text = "Projects" }, { url = "#", text = "Calendar" } ]

        activeLink : String
        activeLink =
            "Dashboard"

        profileLinks : List Link
        profileLinks =
            [ { url = "#", text = "Your Profile" }, { url = "#", text = "Settings" }, { url = "#", text = "Sign out" } ]
    in
    nav [ css [ TwColor.render Bg theme.color L600 ] ]
        [ div [ css [ Tw.mx_auto, Tw.px_2, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_4 ] ] ]
            [ div [ css [ Tw.relative, Tw.flex, Tw.items_center, Tw.justify_between, Tw.h_16 ] ]
                [ div [ css [ Tw.flex, Tw.items_center, Tw.px_2, Bp.lg [ Tw.px_0 ] ] ]
                    [ navbarBrand
                    , navbarSearch theme { id = "search" }
                    ]
                , div [ css [ Tw.flex_1, Tw.flex, Tw.justify_center, Tw.px_2 ] ]
                    [ navbarLinks theme activeLink menuLinks
                    ]
                , navbarMobileButton theme model.mobileMenuOpen
                , div [ css [ Tw.hidden, Bp.lg [ Tw.block, Tw.ml_4 ] ] ]
                    [ div [ css [ Tw.flex, Tw.items_center ] ]
                        [ navbarNotifications theme
                        , navbarProfile theme profileLinks
                        ]
                    ]
                ]
            ]
        , navbarMobileMenu theme model.mobileMenuOpen activeLink menuLinks profileLinks
        ]


navbarBrand : Html msg
navbarBrand =
    a [ href (Route.toHref Route.Projects), css [ Tw.flex, Tw.justify_start, Tw.items_center, Tw.font_medium ] ]
        [ img [ css [ Tw.block, Tw.h_8, Tw.h_8 ], src "/logo.png", alt "Azimutt", width 32, height 32 ] []
        , span [ css [ Tw.ml_3, Tw.text_2xl, Tw.text_white, Tw.hidden, Bp.lg [ Tw.block ] ] ] [ text "Azimutt" ]
        ]


type alias NavbarSearch =
    { id : HtmlId
    }


navbarSearch : Theme -> NavbarSearch -> Html msg
navbarSearch theme search =
    div [ css [ Tw.ml_6 ] ]
        [ div [ css [ Tw.max_w_lg, Tw.w_full, Bp.lg [ Tw.max_w_xs ] ] ]
            [ label [ for search.id, css [ Tw.sr_only ] ] [ text "Search" ]
            , div [ css [ Tw.relative ] ]
                [ div [ css [ Tw.pointer_events_none, Tw.absolute, Tw.inset_y_0, Tw.left_0, Tw.pl_3, Tw.flex, Tw.items_center ] ] [ Icon.solid Search [ TwColor.render Text theme.color L200 ] ]
                , input [ type_ "search", name "search", id search.id, placeholder "Search", css [ Tw.block, Tw.w_full, Tw.pl_10, Tw.pr_3, Tw.py_2, Tw.border, Tw.border_transparent, Tw.rounded_md, Tw.leading_5, TwColor.render Bg theme.color L500, TwColor.render Text theme.color L100, TwColor.render Placeholder theme.color L200, Css.focus [ Tw.outline_none, Tw.bg_white, Tw.border_white, Tw.ring_white, TwColor.render Text theme.color L900, TwColor.render Placeholder theme.color L400 ], Bp.sm [ Tw.text_sm ] ] ] []
                ]
            ]
        ]


navbarLinks : Theme -> String -> List Link -> Html msg
navbarLinks theme active links =
    div [ css [ Tw.hidden, Bp.lg [ Tw.block ] ] ]
        [ div [ css [ Tw.flex, Tw.space_x_4 ] ]
            (links |> List.map (navbarLink [ Tw.text_sm ] theme active))
        ]


navbarMobileButton : Theme -> Bool -> Html msg
navbarMobileButton theme isOpen =
    div [ css [ Tw.flex, Bp.lg [ Tw.hidden ] ] ]
        [ button [ type_ "button", ariaControls "mobile-menu", ariaExpanded False, css [ Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.p_2, Tw.rounded_md, TwColor.render Text theme.color L200, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_inset, Tw.ring_white ], Css.hover [ Tw.text_white, TwColor.render Bg theme.color L500 ] ] ]
            [ span [ css [ Tw.sr_only ] ] [ text "Open main menu" ]
            , Icon.outline Menu [ B.cond isOpen Tw.hidden Tw.block ]
            , Icon.outline X [ B.cond isOpen Tw.block Tw.hidden ]
            ]
        ]


navbarProfile : Theme -> List Link -> Html msg
navbarProfile theme links =
    Dropdown.dropdown { id = "user-menu-button", direction = BottomLeft, isOpen = True }
        (\m ->
            button [ type_ "button", id m.id, ariaExpanded False, ariaHaspopup True, css [ Tw.ml_3, TwColor.render Bg theme.color L600, Tw.rounded_full, Tw.flex, Tw.text_sm, Tw.text_white, Tu.focusRing ( White, L600 ) ( theme.color, L600 ) ] ]
                [ span [ css [ Tw.sr_only ] ] [ text "Open user menu" ]
                , img [ css [ Tw.h_8, Tw.w_8, Tw.rounded_full ], src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
                ]
        )
        (\_ ->
            div [ css [ Tw.w_48 ] ]
                (links |> List.map (\link -> a [ href link.url, role "menuitem", tabindex -1, id "user-menu-item-1", css [ Tw.block, Tw.px_4, Tw.py_2, Tw.text_sm, Tw.text_gray_700, Css.hover [ Tw.bg_gray_100 ] ] ] [ text link.text ]))
        )


navbarMobileMenu : Theme -> Bool -> String -> List Link -> List Link -> Html msg
navbarMobileMenu theme isOpen active menuLinks profileLinks =
    div [ css ([ Bp.lg [ Tw.hidden ] ] ++ B.cond isOpen [] [ Tw.hidden ]), id "mobile-menu" ]
        [ div [ css [ Tw.px_2, Tw.pt_2, Tw.pb_3, Tw.space_y_1 ] ]
            (menuLinks |> List.map (navbarLink [ Tw.text_base ] theme active))
        , div [ css [ Tw.pt_4, Tw.pb_3, Tw.border_t, TwColor.render Border theme.color L500 ] ]
            [ div [ css [ Tw.flex, Tw.items_center, Tw.px_5 ] ]
                [ div [ css [ Tw.flex_shrink_0 ] ]
                    [ img [ css [ Tw.h_10, Tw.w_10, Tw.rounded_full ], src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
                    ]
                , div [ css [ Tw.ml_3 ] ]
                    [ div [ css [ Tw.text_base, Tw.font_medium, Tw.text_white ] ] [ text "Tom Cook" ]
                    , div [ css [ Tw.text_sm, Tw.font_medium, TwColor.render Text theme.color L200 ] ] [ text "tom@example.com" ]
                    ]
                , navbarNotifications theme
                ]
            , div [ css [ Tw.mt_3, Tw.px_2, Tw.space_y_1 ] ]
                (profileLinks |> List.map (\link -> a [ href link.url, css [ Tw.block, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.text_base, Tw.font_medium, TwColor.render Text theme.color L200, Css.hover [ Tw.text_white, TwColor.render Bg theme.color L500 ] ] ] [ text link.text ]))
            ]
        ]


navbarNotifications : Theme -> Html msg
navbarNotifications theme =
    button [ type_ "button", css [ Tw.ml_auto, Tw.flex_shrink_0, TwColor.render Bg theme.color L600, Tw.p_1, Tw.rounded_full, TwColor.render Text theme.color L200, Tu.focusRing ( White, L600 ) ( theme.color, L600 ), Css.hover [ Tw.text_white ] ] ]
        [ span [ css [ Tw.sr_only ] ] [ text "View notifications" ]
        , Icon.outline Bell []
        ]


navbarLink : List Style -> Theme -> String -> Link -> Html msg
navbarLink styles theme active link =
    if link.text == active then
        a [ href link.url, css ([ TwColor.render Bg theme.color L700, Tw.text_white, Tw.block, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.font_medium ] ++ styles) ] [ text link.text ]

    else
        a [ href link.url, css ([ TwColor.render Text theme.color L100, Tw.block, Tw.px_3, Tw.py_2, Tw.rounded_md, Tw.font_medium, Css.hover [ TwColor.render Bg theme.color L500, Tw.text_white ] ] ++ styles) ] [ text link.text ]
