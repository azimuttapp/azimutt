module Components.Organisms.Navbar exposing (AdminBrand, AdminMobileMenu, AdminModel, AdminNavigation, AdminNotifications, AdminProfile, AdminSearch, AdminState, DocState, SharedDocState, admin, doc, initDocState)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Dropdown as Dropdown exposing (Direction(..))
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, a, button, div, img, input, label, nav, span, text)
import Html.Attributes exposing (alt, for, height, href, id, name, placeholder, src, type_, width)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Attributes exposing (ariaControls, ariaCurrent, ariaExpanded, ariaHaspopup, css)
import Libs.Maybe as M
import Libs.Models exposing (Image, Link)
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Tailwind exposing (TwClass, bg_500, bg_600, bg_700, border_300, border_400, border_700, focus, focusRing, focusWithin, hover, lg, ring_offset_600, sm, text_200, text_300)


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
    nav [ css [ "border-b border-opacity-25", bg_600 theme.color, border_300 theme.color, lg "border-none" ] ]
        [ div [ css [ "max-w-7xl mx-auto px-4", lg "px-8", sm "px-6" ] ]
            [ div [ css [ "relative h-16 flex items-center justify-between", lg ("border-b border-opacity-25 " ++ border_400 theme.color) ] ]
                [ div [ css [ "px-2 flex items-center", lg "px-0" ] ]
                    [ div [ css [ "flex-shrink-0" ] ] [ adminBrand model.brand ]
                    , div [ css [ "hidden", lg "block ml-10" ] ] [ adminNavigation theme model.navigation state.selectedMenu ]
                    ]
                , model.search |> M.mapOrElse (adminSearch theme) (div [] [])
                , adminMobileMenuButton theme model.mobileMenu state.mobileMenuOpen
                , div [ css [ "hidden", lg "block ml-4" ] ]
                    [ div [ css [ "flex items-center" ] ]
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
    a [ href brand.link.url, css [ "flex justify-start items-center font-medium" ] ]
        [ img [ css [ "block h-8 w-8" ], src brand.img.src, alt brand.img.alt, width 32, height 32 ] []
        , span [ css [ "ml-3 text-2xl text-white hidden", lg "block" ] ] [ text brand.link.text ]
        ]


adminNavigation : Theme -> AdminNavigation msg -> String -> Html msg
adminNavigation theme navigation navigationActive =
    div [ css [ "flex space-x-4" ] ] (navigation.links |> List.map (adminNavigationLink "text-sm" theme navigationActive navigation.onClick))


adminNavigationLink : TwClass -> Theme -> String -> (Link -> msg) -> Link -> Html msg
adminNavigationLink styles theme navigationActive navigationOnClick link =
    if link.text == navigationActive then
        a [ href link.url, onClick (navigationOnClick link), css [ "text-white rounded-md py-2 px-3 font-medium", bg_700 theme.color, styles ], ariaCurrent "page" ] [ text link.text ]

    else
        a [ href link.url, onClick (navigationOnClick link), css [ "text-white rounded-md py-2 px-3 font-medium", styles, hover ("bg-opacity-75 " ++ bg_500 theme.color) ] ] [ text link.text ]


adminSearch : Theme -> AdminSearch -> Html msg
adminSearch theme search =
    div [ css [ "flex-1 px-2 flex justify-center", lg "ml-6 justify-end" ] ]
        [ div [ css [ "max-w-lg w-full", lg "max-w-xs" ] ]
            [ label [ for search.id, css [ "sr-only" ] ] [ text "Search" ]
            , div [ css [ "relative text-gray-400", focusWithin "text-gray-600" ] ]
                [ div [ css [ "pointer-events-none absolute inset-y-0 left-0 pl-3 flex items-center" ] ] [ Icon.solid Search "" ]
                , input [ type_ "search", name "search", id search.id, placeholder "Search", css [ "block w-full bg-white py-2 pl-10 pr-3 border border-transparent rounded-md leading-5 text-gray-900 placeholder-gray-500", focusRing ( Color.white, 600 ) ( theme.color, 600 ), sm "text-sm" ] ] []
                ]
            ]
        ]


adminMobileMenuButton : Theme -> AdminMobileMenu msg -> Bool -> Html msg
adminMobileMenuButton theme mobileMenu isOpen =
    div [ css [ "flex", lg "hidden" ] ]
        [ button [ type_ "button", onClick mobileMenu.onClick, css [ "p-2 rounded-md inline-flex items-center justify-center", bg_600 theme.color, text_200 theme.color, hover ("text-white bg-opacity-75 " ++ bg_500 theme.color), focus ("outline-none ring-2 ring-offset-2 ring-white " ++ ring_offset_600 theme.color) ], ariaControls mobileMenu.id, ariaExpanded isOpen ]
            [ span [ css [ "sr-only" ] ] [ text "Open main menu" ]
            , Icon.outline Menu (B.cond isOpen "hidden" "block")
            , Icon.outline X (B.cond isOpen "block" "hidden")
            ]
        ]


adminNotifications : Theme -> AdminNotifications -> Html msg
adminNotifications theme _ =
    button [ type_ "button", css [ "ml-auto flex-shrink-0 rounded-full p-1", bg_600 theme.color, text_200 theme.color, hover "text-white", focusRing ( Color.white, 600 ) ( theme.color, 600 ) ] ]
        [ span [ css [ "sr-only" ] ] [ text "View notifications" ]
        , Icon.outline Bell ""
        ]


adminProfile : Theme -> Bool -> AdminProfile msg -> Html msg
adminProfile theme isOpen profile =
    Dropdown.dropdown { id = profile.id, direction = BottomLeft, isOpen = isOpen }
        (\m ->
            button [ type_ "button", id m.id, onClick profile.onClick, css [ "ml-3 rounded-full flex text-sm text-white", bg_600 theme.color, focusRing ( Color.white, 600 ) ( theme.color, 600 ) ], ariaExpanded m.isOpen, ariaHaspopup True ]
                [ span [ css [ "sr-only" ] ] [ text "Open user menu" ]
                , img [ css [ "rounded-full h-8 w-8" ], src profile.avatar, alt "Your avatar", width 32, height 32 ] []
                ]
        )
        (\_ -> div [] (profile.links |> List.map Dropdown.link))


adminMobileMenu : Theme -> AdminNavigation msg -> Maybe AdminNotifications -> Maybe (AdminProfile msg) -> AdminMobileMenu msg -> String -> Bool -> Html msg
adminMobileMenu theme navigation notifications profile mobileMenu activeMenu isOpen =
    div [ css [ lg "hidden", B.cond isOpen "" "hidden" ], id mobileMenu.id ]
        [ adminMobileNavigation theme navigation activeMenu
        , profile
            |> M.mapOrElse
                (\p ->
                    div [ css [ "pt-4 pb-3 border-t", border_700 theme.color ] ]
                        [ div [ css [ "px-5 flex items-center" ] ]
                            [ div [ css [ "flex-shrink-0" ] ]
                                [ img [ css [ "rounded-full h-10 w-10" ], src p.avatar, alt "Your avatar", width 40, height 40 ] []
                                ]
                            , div [ css [ "ml-3" ] ]
                                [ div [ css [ "text-base font-medium text-white" ] ] [ text (p.firstName ++ " " ++ p.lastName) ]
                                , div [ css [ "text-sm font-medium", text_300 theme.color ] ] [ text p.email ]
                                ]
                            , notifications |> M.mapOrElse (adminNotifications theme) (div [] [])
                            ]
                        , div [ css [ "mt-3 px-2 space-y-1" ] ]
                            (p.links |> List.map (\link -> a [ href link.url, css [ "block rounded-md py-2 px-3 text-base font-medium text-white", hover ("bg-opacity-75 " ++ bg_500 theme.color) ] ] [ text link.text ]))
                        ]
                )
                (div [] [])
        ]


adminMobileNavigation : Theme -> AdminNavigation msg -> String -> Html msg
adminMobileNavigation theme navigation navigationActive =
    div [ css [ "px-2 pt-2 pb-3 space-y-1" ] ] (navigation.links |> List.map (adminNavigationLink "block text-base" theme navigationActive navigation.onClick))



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
