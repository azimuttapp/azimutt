module Components.Organisms.Header exposing (AppMobileMenu, AppModel, AppNavigation, AppNotifications, AppProfile, AppSearch, AppState, AppTheme, Brand, DocState, ExtLink, LeftLinksModel, LeftLinksTheme, RightLinksModel, RightLinksTheme, SharedDocState, app, doc, initDocState, leftLinks, leftLinksIndigo, leftLinksWhite, rightLinks, rightLinksIndigo, rightLinksWhite)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import Css exposing (Style, focus, hover)
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, button, div, header, img, input, label, nav, span, text)
import Html.Styled.Attributes exposing (alt, css, for, height, href, id, name, placeholder, src, tabindex, type_, width)
import Html.Styled.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Styled exposing (extLink)
import Libs.Html.Styled.Attributes exposing (ariaControls, ariaCurrent, ariaExpanded, ariaHaspopup, ariaLabel, role)
import Libs.Maybe as M
import Libs.Models exposing (Image, Link)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Libs.Tailwind.Utilities exposing (focusWithin)
import Tailwind.Breakpoints exposing (lg, md, sm)
import Tailwind.Utilities exposing (absolute, bg_gray_100, bg_indigo_50, bg_indigo_500, bg_indigo_600, bg_indigo_700, bg_opacity_75, bg_white, block, border, border_b, border_indigo_500, border_none, border_opacity_25, border_t, border_transparent, border_white, flex, flex_1, flex_shrink_0, flex_wrap, font_medium, h_10, h_16, h_8, hidden, inline_block, inline_flex, inset_y_0, items_center, justify_between, justify_center, justify_end, justify_start, leading_5, left_0, max_w_7xl, max_w_lg, max_w_xs, ml_10, ml_3, ml_4, ml_6, ml_auto, mt_3, mx_auto, outline_none, p_1, p_2, pb_3, pl_10, pl_3, placeholder_gray_500, pointer_events_none, pr_3, pt_2, pt_4, px_0, px_2, px_3, px_4, px_5, px_6, px_8, py_2, py_4, py_6, relative, ring_2, ring_offset_2, ring_white, rounded_full, rounded_md, space_x_10, space_x_4, space_x_6, space_x_8, space_y_1, sr_only, text_2xl, text_base, text_gray_400, text_gray_500, text_gray_600, text_gray_700, text_gray_900, text_indigo_50, text_indigo_600, text_sm, text_white, w_0, w_10, w_48, w_8, w_auto, w_full)


type alias RightLinksModel msg =
    { brand : Brand
    , links : List (ExtLink msg)
    }


type alias Brand =
    { img : Image, link : Link }


type alias ExtLink msg =
    { url : String, content : List (Html msg), external : Bool }


type alias RightLinksTheme =
    { bg : Css.Style, text : List Css.Style }


rightLinksWhite : RightLinksModel msg -> Html msg
rightLinksWhite model =
    rightLinks { bg = bg_white, text = [ text_gray_500, hover [ text_gray_900 ] ] } model


rightLinksIndigo : RightLinksModel msg -> Html msg
rightLinksIndigo model =
    rightLinks { bg = bg_indigo_600, text = [ text_white, hover [ text_indigo_50 ] ] } model


rightLinks : RightLinksTheme -> RightLinksModel msg -> Html msg
rightLinks theme model =
    header [ css [ theme.bg ] ]
        [ div [ css [ flex, justify_between, items_center, max_w_7xl, mx_auto, px_4, py_6, lg [ px_8 ], md [ justify_start, space_x_10 ], sm [ px_6 ] ] ]
            [ a [ href model.brand.link.url, css [ flex, justify_start, items_center, font_medium, lg [ w_0, flex_1 ] ] ]
                [ img [ src model.brand.img.src, alt model.brand.img.alt, css [ h_8, w_auto, sm [ h_10 ] ] ] []
                , span [ css ([ ml_3, text_2xl ] ++ theme.text) ] [ text model.brand.link.text ]
                ]
            , nav [ css [ hidden, space_x_10, md [ flex ] ] ]
                (model.links
                    |> List.map
                        (\l ->
                            if l.external then
                                extLink l.url [ css ([ text_base, font_medium ] ++ theme.text) ] l.content

                            else
                                a [ href l.url, css ([ text_base, font_medium ] ++ theme.text) ] l.content
                        )
                )
            ]
        ]


type alias LeftLinksModel =
    { brand : Brand
    , primary : Link
    , secondary : Link
    , links : List Link
    }


type alias LeftLinksTheme =
    { bg : Css.Style, links : List Css.Style, primary : List Css.Style, secondary : List Css.Style }


leftLinksIndigo : LeftLinksModel -> Html msg
leftLinksIndigo model =
    leftLinks { bg = bg_indigo_600, links = [ text_white, hover [ text_indigo_50 ] ], secondary = [ text_white, bg_indigo_500, hover [ bg_opacity_75 ] ], primary = [ text_indigo_600, bg_white, hover [ bg_indigo_50 ] ] } model


leftLinksWhite : LeftLinksModel -> Html msg
leftLinksWhite model =
    leftLinks { bg = bg_white, links = [ text_gray_500, hover [ text_gray_900 ] ], secondary = [ text_gray_500, hover [ text_gray_900 ] ], primary = [ text_white, bg_indigo_600, hover [ bg_indigo_700 ] ] } model


leftLinks : LeftLinksTheme -> LeftLinksModel -> Html msg
leftLinks theme model =
    header [ css [ theme.bg ] ]
        [ nav [ css [ max_w_7xl, mx_auto, px_4, lg [ px_8 ], sm [ px_6 ] ], ariaLabel "Top" ]
            [ div [ css [ w_full, py_6, flex, items_center, justify_between, border_b, border_indigo_500, lg [ border_none ] ] ]
                [ div [ css [ flex, items_center ] ]
                    [ a [ href model.brand.link.url ] [ span [ css [ sr_only ] ] [ text model.brand.link.text ], img [ css [ h_10, w_auto ], src model.brand.img.src, alt model.brand.img.alt ] [] ]
                    , div [ css [ hidden, ml_10, space_x_8, lg [ block ] ] ]
                        (model.links |> List.map (\link -> a [ href link.url, css ([ text_base, font_medium ] ++ theme.links) ] [ text link.text ]))
                    ]
                , div [ css [ ml_10, space_x_4 ] ]
                    [ a [ href model.secondary.url, css ([ inline_block, py_2, px_4, border, border_transparent, rounded_md, text_base, font_medium ] ++ theme.secondary) ] [ text model.secondary.text ]
                    , a [ href model.primary.url, css ([ inline_block, py_2, px_4, border, border_transparent, rounded_md, text_base, font_medium ] ++ theme.primary) ] [ text model.primary.text ]
                    ]
                ]
            , div [ css [ py_4, flex, flex_wrap, justify_center, space_x_6, lg [ hidden ] ] ]
                (model.links |> List.map (\link -> a [ href link.url, css ([ text_base, font_medium ] ++ theme.links) ] [ text link.text ]))
            ]
        ]


type alias AppModel msg =
    { theme : AppTheme
    , brand : Brand
    , navigation : AppNavigation msg
    , search : Maybe AppSearch
    , notifications : Maybe AppNotifications
    , profile : Maybe (AppProfile msg)
    , mobileMenu : AppMobileMenu msg
    }


type alias AppTheme =
    { color : TwColor }


type alias AppNavigation msg =
    { links : List Link
    , onClick : Link -> msg
    }


type alias AppSearch =
    { id : HtmlId }


type alias AppNotifications =
    {}


type alias AppProfile msg =
    { id : HtmlId
    , avatar : String
    , firstName : String
    , lastName : String
    , email : String
    , links : List Link
    , onClick : msg
    }


type alias AppMobileMenu msg =
    { id : HtmlId
    , onClick : msg
    }


type alias AppState =
    { navigationActive : String
    , mobileMenuOpen : Bool
    , profileOpen : Bool
    }


app : AppModel msg -> AppState -> Html msg
app model state =
    nav [ css [ TwColor.render Bg model.theme.color L600, border_b, TwColor.render Border model.theme.color L300, border_opacity_25, lg [ border_none ] ] ]
        [ div [ css [ max_w_7xl, mx_auto, px_4, lg [ px_8 ], sm [ px_6 ] ] ]
            [ div [ css [ relative, h_16, flex, items_center, justify_between, lg [ border_b, TwColor.render Border model.theme.color L400, border_opacity_25 ] ] ]
                [ div [ css [ px_2, flex, items_center, lg [ px_0 ] ] ]
                    [ div [ css [ flex_shrink_0 ] ] [ appBrand model.brand ]
                    , div [ css [ hidden, lg [ block, ml_10 ] ] ] [ appNavigation model.theme model.navigation state.navigationActive ]
                    ]
                , model.search |> M.mapOrElse (appSearch model.theme) (div [] [])
                , appMobileMenuButton model.theme model.mobileMenu state.mobileMenuOpen
                , div [ css [ hidden, lg [ block, ml_4 ] ] ]
                    [ div [ css [ flex, items_center ] ]
                        [ model.notifications |> M.mapOrElse (appNotifications model.theme) (div [] [])
                        , model.profile |> M.mapOrElse (appProfile model.theme state.profileOpen) (div [] [])
                        ]
                    ]
                ]
            ]
        , appMobileMenu model.theme model.navigation model.notifications model.profile model.mobileMenu state.navigationActive state.mobileMenuOpen
        ]


appBrand : Brand -> Html msg
appBrand brand =
    a [ href brand.link.url ] [ img [ css [ block, h_8, w_8 ], src brand.img.src, alt brand.img.alt, width 32, height 32 ] [] ]


appNavigation : AppTheme -> AppNavigation msg -> String -> Html msg
appNavigation theme navigation navigationActive =
    div [ css [ flex, space_x_4 ] ] (navigation.links |> List.map (appNavigationLink [ text_sm ] theme navigationActive navigation.onClick))


appNavigationLink : List Style -> AppTheme -> String -> (Link -> msg) -> Link -> Html msg
appNavigationLink styles theme navigationActive navigationOnClick link =
    if link.text == navigationActive then
        a [ href link.url, onClick (navigationOnClick link), css ([ text_white, rounded_md, py_2, px_3, font_medium, TwColor.render Bg theme.color L700 ] ++ styles), ariaCurrent "page" ] [ text link.text ]

    else
        a [ href link.url, onClick (navigationOnClick link), css ([ text_white, rounded_md, py_2, px_3, font_medium, hover [ TwColor.render Bg theme.color L500, bg_opacity_75 ] ] ++ styles) ] [ text link.text ]


appSearch : AppTheme -> AppSearch -> Html msg
appSearch theme search =
    div [ css [ flex_1, px_2, flex, justify_center, lg [ ml_6, justify_end ] ] ]
        [ div [ css [ max_w_lg, w_full, lg [ max_w_xs ] ] ]
            [ label [ for search.id, css [ sr_only ] ] [ text "Search" ]
            , div [ css [ relative, text_gray_400, focusWithin [ text_gray_600 ] ] ]
                [ div [ css [ pointer_events_none, absolute, inset_y_0, left_0, pl_3, flex, items_center ] ] [ Icon.solid Search [] ]
                , input [ type_ "search", name "search", id search.id, placeholder "Search", css [ block, w_full, bg_white, py_2, pl_10, pr_3, border, border_transparent, rounded_md, leading_5, text_gray_900, placeholder_gray_500, focus [ outline_none, ring_2, ring_offset_2, TwColor.render RingOffset theme.color L600, ring_white, border_white ], sm [ text_sm ] ] ] []
                ]
            ]
        ]


appMobileMenuButton : AppTheme -> AppMobileMenu msg -> Bool -> Html msg
appMobileMenuButton theme mobileMenu isOpen =
    div [ css [ flex, lg [ hidden ] ] ]
        [ button [ type_ "button", onClick mobileMenu.onClick, css [ TwColor.render Bg theme.color L600, p_2, rounded_md, inline_flex, items_center, justify_center, TwColor.render Text theme.color L200, focus [ outline_none, ring_2, ring_offset_2, TwColor.render RingOffset theme.color L600, ring_white ], hover [ text_white, TwColor.render Bg theme.color L500, bg_opacity_75 ] ], ariaControls mobileMenu.id, ariaExpanded isOpen ]
            [ span [ css [ sr_only ] ] [ text "Open main menu" ]
            , Icon.outline Menu [ B.cond isOpen hidden block ]
            , Icon.outline X [ B.cond isOpen block hidden ]
            ]
        ]


appNotifications : AppTheme -> AppNotifications -> Html msg
appNotifications theme _ =
    button [ type_ "button", css [ ml_auto, TwColor.render Bg theme.color L600, flex_shrink_0, rounded_full, p_1, TwColor.render Text theme.color L200, focus [ outline_none, ring_2, ring_offset_2, TwColor.render RingOffset theme.color L600, ring_white ], hover [ text_white ] ] ]
        [ span [ css [ sr_only ] ] [ text "View notifications" ]
        , Icon.outline Bell []
        ]


appProfile : AppTheme -> Bool -> AppProfile msg -> Html msg
appProfile theme isOpen profile =
    Dropdown.dropdown { id = profile.id, direction = BottomLeft, isOpen = isOpen }
        (\m ->
            button [ type_ "button", id m.id, onClick profile.onClick, css [ ml_3, TwColor.render Bg theme.color L600, rounded_full, flex, text_sm, text_white, focus [ outline_none, ring_2, ring_offset_2, TwColor.render RingOffset theme.color L600, ring_white ] ], ariaExpanded isOpen, ariaHaspopup True ]
                [ span [ css [ sr_only ] ] [ text "Open user menu" ]
                , img [ css [ rounded_full, h_8, w_8 ], src profile.avatar, alt "Your avatar", width 32, height 32 ] []
                ]
        )
        (\_ ->
            div [ css [ w_48 ] ]
                (profile.links |> List.map (\link -> a [ href link.url, role "menuitem", tabindex -1, css [ block, py_2, px_4, text_sm, text_gray_700, hover [ bg_gray_100 ] ] ] [ text link.text ]))
        )


appMobileMenu : AppTheme -> AppNavigation msg -> Maybe AppNotifications -> Maybe (AppProfile msg) -> AppMobileMenu msg -> String -> Bool -> Html msg
appMobileMenu theme navigation notifications profile mobileMenu activeMenu isOpen =
    let
        open : List Style
        open =
            if isOpen then
                []

            else
                [ hidden ]
    in
    div [ css ([ lg [ hidden ] ] ++ open), id mobileMenu.id ]
        [ appMobileNavigation theme navigation activeMenu
        , profile
            |> M.mapOrElse
                (\p ->
                    div [ css [ pt_4, pb_3, border_t, TwColor.render Border theme.color L700 ] ]
                        [ div [ css [ px_5, flex, items_center ] ]
                            [ div [ css [ flex_shrink_0 ] ]
                                [ img [ css [ rounded_full, h_10, w_10 ], src p.avatar, alt "Your avatar", width 40, height 40 ] []
                                ]
                            , div [ css [ ml_3 ] ]
                                [ div [ css [ text_base, font_medium, text_white ] ] [ text (p.firstName ++ " " ++ p.lastName) ]
                                , div [ css [ text_sm, font_medium, TwColor.render Text theme.color L300 ] ] [ text p.email ]
                                ]
                            , notifications |> M.mapOrElse (appNotifications theme) (div [] [])
                            ]
                        , div [ css [ mt_3, px_2, space_y_1 ] ]
                            (p.links |> List.map (\link -> a [ href link.url, css [ block, rounded_md, py_2, px_3, text_base, font_medium, text_white, hover [ TwColor.render Bg theme.color L500, bg_opacity_75 ] ] ] [ text link.text ]))
                        ]
                )
                (div [] [])
        ]


appMobileNavigation : AppTheme -> AppNavigation msg -> String -> Html msg
appMobileNavigation theme navigation navigationActive =
    div [ css [ px_2, pt_2, pb_3, space_y_1 ] ] (navigation.links |> List.map (appNavigationLink [ block, text_base ] theme navigationActive navigation.onClick))



-- DOCUMENTATION


logoWhite : String
logoWhite =
    "https://tailwindui.com/img/logos/workflow-mark.svg?color=white"


logoIndigo : String
logoIndigo =
    "https://tailwindui.com/img/logos/workflow-mark-indigo-600.svg"


appModel : AppModel (Msg (SharedDocState x))
appModel =
    { theme = { color = Indigo }
    , brand = { img = { src = logoWhite, alt = "Workflow" }, link = { url = "#", text = "Workflow" } }
    , navigation =
        { links =
            [ { url = "#", text = "Dashboard" }
            , { url = "#", text = "Team" }
            , { url = "#", text = "Projects" }
            , { url = "#", text = "Calendar" }
            , { url = "#", text = "Reports" }
            ]
        , onClick = \link -> updateAppState (\a -> { a | navigationActive = link.text })
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
                [ { url = "#", text = "Your profile" }
                , { url = "#", text = "Settings" }
                , { url = "#", text = "Sign out" }
                ]
            , onClick = updateAppState (\a -> { a | profileOpen = not a.profileOpen })
            }
    , mobileMenu = { id = "mobile-menu", onClick = updateAppState (\a -> { a | mobileMenuOpen = not a.mobileMenuOpen }) }
    }


rightLinksModel : String -> RightLinksModel msg
rightLinksModel img =
    { brand = { img = { src = img, alt = "Workflow" }, link = { url = "#", text = "Workflow" } }
    , links =
        [ { url = "#", content = [ text "Solutions" ], external = False }
        , { url = "#", content = [ text "Pricing" ], external = False }
        , { url = "#", content = [ text "Docs" ], external = False }
        , { url = "#", content = [ text "Company" ], external = False }
        ]
    }


leftLinksModel : String -> LeftLinksModel
leftLinksModel img =
    { brand = { img = { src = img, alt = "Workflow" }, link = { url = "#", text = "Workflow" } }
    , primary = { url = "#", text = "Sign up" }
    , secondary = { url = "#", text = "Sign in" }
    , links =
        [ { url = "#", text = "Solutions" }
        , { url = "#", text = "Pricing" }
        , { url = "#", text = "Docs" }
        , { url = "#", text = "Company" }
        ]
    }


type alias SharedDocState x =
    { x | headerDocState : DocState }


type alias DocState =
    { app : AppState }


initDocState : DocState
initDocState =
    { app =
        { navigationActive = "Dashboard"
        , mobileMenuOpen = False
        , profileOpen = False
        }
    }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | headerDocState = transform s.headerDocState })


updateAppState : (AppState -> AppState) -> Msg (SharedDocState x)
updateAppState transform =
    updateDocState (\d -> { d | app = transform d.app })


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Header"
        |> Chapter.renderStatefulComponentList
            [ ( "app", \{ headerDocState } -> app appModel headerDocState.app )
            , ( "rightLinksIndigo", \_ -> rightLinksIndigo (rightLinksModel logoWhite) )
            , ( "rightLinksWhite", \_ -> rightLinksWhite (rightLinksModel logoIndigo) )
            , ( "rightLinks", \_ -> rightLinks { bg = bg_white, text = [] } (rightLinksModel logoIndigo) )
            , ( "leftLinksIndigo", \_ -> leftLinksIndigo (leftLinksModel logoWhite) )
            , ( "leftLinksWhite", \_ -> leftLinksWhite (leftLinksModel logoIndigo) )
            , ( "leftLinks", \_ -> leftLinks { bg = bg_white, links = [], secondary = [], primary = [] } (leftLinksModel logoIndigo) )
            ]
