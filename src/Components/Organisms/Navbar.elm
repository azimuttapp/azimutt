module Components.Organisms.Navbar exposing (AdminBrand, AdminModel, AdminNavigation, AdminNotifications, AdminProfile, AdminSearch, AdminState, DocState, SharedDocState, admin, doc, initDocState)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, a, button, div, img, input, label, nav, span, text)
import Html.Attributes exposing (alt, for, height, href, id, name, placeholder, src, type_, width)
import Html.Events exposing (onClick)
import Libs.Html.Attributes exposing (ariaCurrent, ariaExpanded, ariaHaspopup, css)
import Libs.Maybe as Maybe
import Libs.Models exposing (Image, Link)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (TwClass, focusWithin, focus_ring_offset_600, hover, lg, sm)


type alias AdminModel msg =
    { brand : AdminBrand
    , navigation : AdminNavigation msg
    , search : Maybe AdminSearch
    , rightIcons : List (Html msg)
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


type alias AdminState =
    { selectedMenu : String
    , profileOpen : Bool
    }


admin : AdminModel msg -> AdminState -> Html msg
admin model state =
    nav [ css [ "border-b border-opacity-25 bg-primary-600 border-primary-300", lg [ "border-none" ] ] ]
        [ div [ css [ "max-w-7xl mx-auto px-4", lg [ "px-8" ], sm [ "px-6" ] ] ]
            [ div [ css [ "relative h-16 flex items-center justify-between", lg [ "border-b border-opacity-25 border-primary-400" ] ] ]
                [ div [ css [ "px-2 flex items-center", lg [ "px-0" ] ] ]
                    [ div [ css [ "flex-shrink-0" ] ] [ adminBrand model.brand ]
                    , div [ css [ "hidden", lg [ "block ml-10" ] ] ] [ adminNavigation model.navigation state.selectedMenu ]
                    ]
                , model.search |> Maybe.mapOrElse adminSearch (div [] [])
                , div [ css [ "hidden", lg [ "block ml-4" ] ] ]
                    [ div [ css [ "flex items-center" ] ] model.rightIcons
                    ]
                ]
            ]
        ]


adminBrand : AdminBrand -> Html msg
adminBrand brand =
    a [ href brand.link.url, css [ "flex justify-start items-center" ] ]
        [ img [ css [ "block h-8 w-8" ], src brand.img.src, alt brand.img.alt, width 32, height 32 ] []
        , span [ css [ "ml-3 text-2xl text-white font-medium hidden", lg [ "block" ] ] ] [ text brand.link.text ]
        ]


adminNavigation : AdminNavigation msg -> String -> Html msg
adminNavigation navigation navigationActive =
    div [ css [ "flex space-x-4" ] ] (navigation.links |> List.map (adminNavigationLink "text-sm" navigationActive navigation.onClick))


adminNavigationLink : TwClass -> String -> (Link -> msg) -> Link -> Html msg
adminNavigationLink styles navigationActive navigationOnClick link =
    if link.text == navigationActive then
        a [ href link.url, onClick (navigationOnClick link), css [ "text-white rounded-md py-2 px-3 font-medium bg-primary-700", styles ], ariaCurrent "page" ] [ text link.text ]

    else
        a [ href link.url, onClick (navigationOnClick link), css [ "text-white rounded-md py-2 px-3 font-medium", styles, hover [ "bg-opacity-75 bg-primary-500" ] ] ] [ text link.text ]


adminSearch : AdminSearch -> Html msg
adminSearch search =
    div [ css [ "flex-1 px-2 flex justify-center", lg [ "ml-6 justify-end" ] ] ]
        [ div [ css [ "max-w-lg w-full", lg [ "max-w-xs" ] ] ]
            [ label [ for search.id, css [ "sr-only" ] ] [ text "Search" ]
            , div [ css [ "relative text-gray-400", focusWithin [ "]text-gray-600" ] ] ]
                [ div [ css [ "pointer-events-none absolute inset-y-0 left-0 pl-3 flex items-center" ] ] [ Icon.solid Search "" ]
                , input [ type_ "search", name "search", id search.id, placeholder "Search", css [ "block w-full bg-white py-2 pl-10 pr-3 border border-transparent rounded-md leading-5 text-gray-900 placeholder-gray-500", focus_ring_offset_600 Tw.primary, sm [ "text-sm" ] ] ] []
                ]
            ]
        ]


adminNotifications : AdminNotifications -> Html msg
adminNotifications _ =
    button [ type_ "button", css [ "ml-auto flex-shrink-0 rounded-full p-1 bg-primary-600 text-primary-200", hover [ "text-white" ], focus_ring_offset_600 Tw.primary ] ]
        [ span [ css [ "sr-only" ] ] [ text "View notifications" ]
        , Icon.outline Bell ""
        ]


adminProfile : Bool -> AdminProfile msg -> Html msg
adminProfile isOpen profile =
    Dropdown.dropdown { id = profile.id, direction = BottomLeft, isOpen = isOpen }
        (\m ->
            button [ type_ "button", id m.id, onClick profile.onClick, css [ "ml-3 rounded-full flex text-sm text-white bg-primary-600", focus_ring_offset_600 Tw.primary ], ariaExpanded m.isOpen, ariaHaspopup True ]
                [ span [ css [ "sr-only" ] ] [ text "Open user menu" ]
                , img [ css [ "rounded-full h-8 w-8" ], src profile.avatar, alt "Your avatar", width 32, height 32 ] []
                ]
        )
        (\_ -> div [] (profile.links |> List.map ContextMenu.link))



-- DOCUMENTATION


logoWhite : String
logoWhite =
    "https://tailwindui.com/img/logos/workflow-mark.svg?color=white"


adminModel : AdminState -> AdminModel (Msg (SharedDocState x))
adminModel s =
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
    , rightIcons =
        [ adminNotifications {}
        , adminProfile s.profileOpen
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
        ]
    }


type alias SharedDocState x =
    { x | navbarDocState : DocState }


type alias DocState =
    { app : AdminState }


initDocState : DocState
initDocState =
    { app =
        { selectedMenu = "Dashboard"
        , profileOpen = False
        }
    }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | navbarDocState = s.navbarDocState |> transform })


updateAppState : (AdminState -> AdminState) -> Msg (SharedDocState x)
updateAppState transform =
    updateDocState (\d -> { d | app = transform d.app })


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Navbar"
        |> Chapter.renderStatefulComponentList
            [ ( "admin", \{ navbarDocState } -> admin (adminModel navbarDocState.app) navbarDocState.app )
            ]
