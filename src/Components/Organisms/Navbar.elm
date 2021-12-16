module Components.Organisms.Navbar exposing (AdminBrand, AdminMobileMenu, AdminModel, AdminNavigation, AdminNotifications, AdminProfile, AdminSearch, AdminState, DocState, SharedDocState, admin, doc, initDocState)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Css exposing (Style)
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, button, div, img, input, label, nav, span, text)
import Html.Styled.Attributes exposing (alt, css, for, height, href, id, name, placeholder, src, type_, width)
import Html.Styled.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Styled.Attributes exposing (ariaControls, ariaCurrent, ariaExpanded, ariaHaspopup)
import Libs.Maybe as M
import Libs.Models exposing (Image, Link)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Libs.Tailwind.Utilities as Tu
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias AdminModel msg =
    { brand : AdminBrand
    , navigation : AdminNavigation msg
    , search : Maybe AdminSearch
    , notifications : Maybe AdminNotifications
    , profile : Maybe (AdminProfile msg)
    , mobileMenu : AdminMobileMenu msg
    }


type alias AdminBrand =
    { img : Image, link : Link }


type alias AdminNavigation msg =
    { links : List Link
    , onClick : Link -> msg
    }


type alias AdminSearch =
    { id : HtmlId }


type alias AdminNotifications =
    {}


type alias AdminProfile msg =
    { id : HtmlId
    , avatar : String
    , firstName : String
    , lastName : String
    , email : String
    , links : List Link
    , onClick : msg
    }


type alias AdminMobileMenu msg =
    { id : HtmlId
    , onClick : msg
    }


type alias AdminState =
    { selectedMenu : String
    , mobileMenuOpen : Bool
    , profileOpen : Bool
    }


admin : Theme -> AdminModel msg -> AdminState -> Html msg
admin theme model state =
    nav [ css [ TwColor.render Bg theme.color L600, Tw.border_b, TwColor.render Border theme.color L300, Tw.border_opacity_25, Bp.lg [ Tw.border_none ] ] ]
        [ div [ css [ Tw.max_w_7xl, Tw.mx_auto, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_6 ] ] ]
            [ div [ css [ Tw.relative, Tw.h_16, Tw.flex, Tw.items_center, Tw.justify_between, Bp.lg [ Tw.border_b, TwColor.render Border theme.color L400, Tw.border_opacity_25 ] ] ]
                [ div [ css [ Tw.px_2, Tw.flex, Tw.items_center, Bp.lg [ Tw.px_0 ] ] ]
                    [ div [ css [ Tw.flex_shrink_0 ] ] [ adminBrand model.brand ]
                    , div [ css [ Tw.hidden, Bp.lg [ Tw.block, Tw.ml_10 ] ] ] [ adminNavigation theme model.navigation state.selectedMenu ]
                    ]
                , model.search |> M.mapOrElse (adminSearch theme) (div [] [])
                , adminMobileMenuButton theme model.mobileMenu state.mobileMenuOpen
                , div [ css [ Tw.hidden, Bp.lg [ Tw.block, Tw.ml_4 ] ] ]
                    [ div [ css [ Tw.flex, Tw.items_center ] ]
                        [ model.notifications |> M.mapOrElse (adminNotifications theme) (div [] [])
                        , model.profile |> M.mapOrElse (adminProfile theme state.profileOpen) (div [] [])
                        ]
                    ]
                ]
            ]
        , adminMobileMenu theme model.navigation model.notifications model.profile model.mobileMenu state.selectedMenu state.mobileMenuOpen
        ]


adminBrand : AdminBrand -> Html msg
adminBrand brand =
    a [ href brand.link.url, css [ Tw.flex, Tw.justify_start, Tw.items_center, Tw.font_medium ] ]
        [ img [ css [ Tw.block, Tw.h_8, Tw.w_8 ], src brand.img.src, alt brand.img.alt, width 32, height 32 ] []
        , span [ css [ Tw.ml_3, Tw.text_2xl, Tw.text_white, Tw.hidden, Bp.lg [ Tw.block ] ] ] [ text brand.link.text ]
        ]


adminNavigation : Theme -> AdminNavigation msg -> String -> Html msg
adminNavigation theme navigation navigationActive =
    div [ css [ Tw.flex, Tw.space_x_4 ] ] (navigation.links |> List.map (adminNavigationLink [ Tw.text_sm ] theme navigationActive navigation.onClick))


adminNavigationLink : List Style -> Theme -> String -> (Link -> msg) -> Link -> Html msg
adminNavigationLink styles theme navigationActive navigationOnClick link =
    if link.text == navigationActive then
        a [ href link.url, onClick (navigationOnClick link), css ([ Tw.text_white, Tw.rounded_md, Tw.py_2, Tw.px_3, Tw.font_medium, TwColor.render Bg theme.color L700 ] ++ styles), ariaCurrent "page" ] [ text link.text ]

    else
        a [ href link.url, onClick (navigationOnClick link), css ([ Tw.text_white, Tw.rounded_md, Tw.py_2, Tw.px_3, Tw.font_medium, Css.hover [ TwColor.render Bg theme.color L500, Tw.bg_opacity_75 ] ] ++ styles) ] [ text link.text ]


adminSearch : Theme -> AdminSearch -> Html msg
adminSearch theme search =
    div [ css [ Tw.flex_1, Tw.px_2, Tw.flex, Tw.justify_center, Bp.lg [ Tw.ml_6, Tw.justify_end ] ] ]
        [ div [ css [ Tw.max_w_lg, Tw.w_full, Bp.lg [ Tw.max_w_xs ] ] ]
            [ label [ for search.id, css [ Tw.sr_only ] ] [ text "Search" ]
            , div [ css [ Tw.relative, Tw.text_gray_400, Tu.focusWithin [ Tw.text_gray_600 ] ] ]
                [ div [ css [ Tw.pointer_events_none, Tw.absolute, Tw.inset_y_0, Tw.left_0, Tw.pl_3, Tw.flex, Tw.items_center ] ] [ Icon.solid Search [] ]
                , input [ type_ "search", name "search", id search.id, placeholder "Search", css [ Tw.block, Tw.w_full, Tw.bg_white, Tw.py_2, Tw.pl_10, Tw.pr_3, Tw.border, Tw.border_transparent, Tw.rounded_md, Tw.leading_5, Tw.text_gray_900, Tw.placeholder_gray_500, Tu.focusRing ( White, L600 ) ( theme.color, L600 ), Bp.sm [ Tw.text_sm ] ] ] []
                ]
            ]
        ]


adminMobileMenuButton : Theme -> AdminMobileMenu msg -> Bool -> Html msg
adminMobileMenuButton theme mobileMenu isOpen =
    div [ css [ Tw.flex, Bp.lg [ Tw.hidden ] ] ]
        [ button [ type_ "button", onClick mobileMenu.onClick, css [ TwColor.render Bg theme.color L600, Tw.p_2, Tw.rounded_md, Tw.inline_flex, Tw.items_center, Tw.justify_center, TwColor.render Text theme.color L200, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, TwColor.render RingOffset theme.color L600, Tw.ring_white ], Css.hover [ Tw.text_white, TwColor.render Bg theme.color L500, Tw.bg_opacity_75 ] ], ariaControls mobileMenu.id, ariaExpanded isOpen ]
            [ span [ css [ Tw.sr_only ] ] [ text "Open main menu" ]
            , Icon.outline Menu [ B.cond isOpen Tw.hidden Tw.block ]
            , Icon.outline X [ B.cond isOpen Tw.block Tw.hidden ]
            ]
        ]


adminNotifications : Theme -> AdminNotifications -> Html msg
adminNotifications theme _ =
    button [ type_ "button", css [ Tw.ml_auto, TwColor.render Bg theme.color L600, Tw.flex_shrink_0, Tw.rounded_full, Tw.p_1, TwColor.render Text theme.color L200, Tu.focusRing ( White, L600 ) ( theme.color, L600 ), Css.hover [ Tw.text_white ] ] ]
        [ span [ css [ Tw.sr_only ] ] [ text "View notifications" ]
        , Icon.outline Bell []
        ]


adminProfile : Theme -> Bool -> AdminProfile msg -> Html msg
adminProfile theme isOpen profile =
    Dropdown.dropdown { id = profile.id, direction = BottomLeft, isOpen = isOpen }
        (\m ->
            button [ type_ "button", id m.id, onClick profile.onClick, css [ Tw.ml_3, TwColor.render Bg theme.color L600, Tw.rounded_full, Tw.flex, Tw.text_sm, Tw.text_white, Tu.focusRing ( White, L600 ) ( theme.color, L600 ) ], ariaExpanded m.isOpen, ariaHaspopup True ]
                [ span [ css [ Tw.sr_only ] ] [ text "Open user menu" ]
                , img [ css [ Tw.rounded_full, Tw.h_8, Tw.w_8 ], src profile.avatar, alt "Your avatar", width 32, height 32 ] []
                ]
        )
        (Dropdown.menuLinks profile.links)


adminMobileMenu : Theme -> AdminNavigation msg -> Maybe AdminNotifications -> Maybe (AdminProfile msg) -> AdminMobileMenu msg -> String -> Bool -> Html msg
adminMobileMenu theme navigation notifications profile mobileMenu activeMenu isOpen =
    let
        open : List Style
        open =
            if isOpen then
                []

            else
                [ Tw.hidden ]
    in
    div [ css ([ Bp.lg [ Tw.hidden ] ] ++ open), id mobileMenu.id ]
        [ adminMobileNavigation theme navigation activeMenu
        , profile
            |> M.mapOrElse
                (\p ->
                    div [ css [ Tw.pt_4, Tw.pb_3, Tw.border_t, TwColor.render Border theme.color L700 ] ]
                        [ div [ css [ Tw.px_5, Tw.flex, Tw.items_center ] ]
                            [ div [ css [ Tw.flex_shrink_0 ] ]
                                [ img [ css [ Tw.rounded_full, Tw.h_10, Tw.w_10 ], src p.avatar, alt "Your avatar", width 40, height 40 ] []
                                ]
                            , div [ css [ Tw.ml_3 ] ]
                                [ div [ css [ Tw.text_base, Tw.font_medium, Tw.text_white ] ] [ text (p.firstName ++ " " ++ p.lastName) ]
                                , div [ css [ Tw.text_sm, Tw.font_medium, TwColor.render Text theme.color L300 ] ] [ text p.email ]
                                ]
                            , notifications |> M.mapOrElse (adminNotifications theme) (div [] [])
                            ]
                        , div [ css [ Tw.mt_3, Tw.px_2, Tw.space_y_1 ] ]
                            (p.links |> List.map (\link -> a [ href link.url, css [ Tw.block, Tw.rounded_md, Tw.py_2, Tw.px_3, Tw.text_base, Tw.font_medium, Tw.text_white, Css.hover [ TwColor.render Bg theme.color L500, Tw.bg_opacity_75 ] ] ] [ text link.text ]))
                        ]
                )
                (div [] [])
        ]


adminMobileNavigation : Theme -> AdminNavigation msg -> String -> Html msg
adminMobileNavigation theme navigation navigationActive =
    div [ css [ Tw.px_2, Tw.pt_2, Tw.pb_3, Tw.space_y_1 ] ] (navigation.links |> List.map (adminNavigationLink [ Tw.block, Tw.text_base ] theme navigationActive navigation.onClick))



-- DOCUMENTATION


logoWhite : String
logoWhite =
    "https://tailwindui.com/img/logos/workflow-mark.svg?color=white"


adminModel : AdminModel (Msg (SharedDocState x))
adminModel =
    { brand = { img = { src = logoWhite, alt = "Workflow" }, link = { url = "#", text = "Workflow" } }
    , navigation =
        { links =
            [ { url = "", text = "Dashboard" }
            , { url = "", text = "Team" }
            , { url = "", text = "Projects" }
            , { url = "", text = "Calendar" }
            , { url = "", text = "Reports" }
            ]
        , onClick = \link -> updateAppState (\a -> { a | selectedMenu = link.text })
        }
    , search = Just { id = "search" }
    , notifications = Just {}
    , profile =
        Just
            { id = "profile-dropdown"
            , avatar = "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
            , firstName = "John"
            , lastName = "Doe"
            , email = "john.doe@mail.com"
            , links =
                [ { url = "", text = "Your profile" }
                , { url = "", text = "Settings" }
                , { url = "", text = "Sign out" }
                ]
            , onClick = updateAppState (\a -> { a | profileOpen = not a.profileOpen })
            }
    , mobileMenu = { id = "mobile-menu", onClick = updateAppState (\a -> { a | mobileMenuOpen = not a.mobileMenuOpen }) }
    }


type alias SharedDocState x =
    { x | navbarDocState : DocState }


type alias DocState =
    { app : AdminState }


initDocState : DocState
initDocState =
    { app =
        { selectedMenu = "Dashboard"
        , mobileMenuOpen = False
        , profileOpen = False
        }
    }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | navbarDocState = s.navbarDocState |> transform })


updateAppState : (AdminState -> AdminState) -> Msg (SharedDocState x)
updateAppState transform =
    updateDocState (\d -> { d | app = transform d.app })


doc : Theme -> Chapter (SharedDocState x)
doc theme =
    Chapter.chapter "Navbar"
        |> Chapter.renderStatefulComponentList
            [ ( "admin", \{ navbarDocState } -> admin theme adminModel navbarDocState.app )
            ]
