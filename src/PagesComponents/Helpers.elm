module PagesComponents.Helpers exposing (appShell, viewProfileIcon)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Tooltip as Tooltip
import Components.Organisms.Navbar as Navbar
import Conf
import Gen.Route as Route
import Html exposing (Html, a, button, div, footer, h1, header, img, main_, p, span, text)
import Html.Attributes exposing (alt, class, height, href, id, src, type_, width)
import Html.Events exposing (onClick)
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css)
import Libs.Maybe as Maybe
import Libs.Models exposing (Link)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (focus_ring_offset_600, hover, lg, md, sm)
import Models.User as User exposing (User)
import Router
import Url exposing (Url)


appShell :
    Url
    -> Maybe User
    -> (Link -> msg)
    -> (HtmlId -> msg)
    -> msg
    -> { x | selectedMenu : String, mobileMenuOpen : Bool, openedDropdown : HtmlId }
    -> List (Html msg)
    -> List (Html msg)
    -> List (Html msg)
    -> List (Html msg)
appShell currentUrl maybeUser onNavigationClick onProfileClick onLogout model title content footer =
    let
        profileDropdown : HtmlId
        profileDropdown =
            "shell-profile-dropdown"
    in
    [ div [ css [ "pb-32 bg-primary-600" ] ]
        [ Navbar.admin
            { brand = { img = { src = "/logo.png", alt = "Azimutt" }, link = { url = Route.toHref Route.Home_, text = "Azimutt" } }
            , navigation =
                { links = [ { url = Route.toHref Route.Projects, text = "Dashboard" } ]
                , onClick = onNavigationClick
                }
            , search = Nothing
            , rightIcons =
                [ viewProfileIcon currentUrl maybeUser profileDropdown model.openedDropdown onProfileClick onLogout ]
            }
            { selectedMenu = model.selectedMenu
            , profileOpen = model.openedDropdown == profileDropdown
            }
        , viewHeader title
        ]
    , div [ css [ "-mt-32" ] ]
        [ main_ [ css [ "max-w-7xl mx-auto pb-12 px-4", sm [ "px-6" ], lg [ "px-8" ] ] ]
            [ div [ css [ "bg-white rounded-lg shadow" ] ] content
            ]
        ]
    ]
        ++ (viewFooter :: footer)


viewProfileIcon : Url -> Maybe User -> HtmlId -> HtmlId -> (HtmlId -> msg) -> msg -> Html msg
viewProfileIcon currentUrl maybeUser profileDropdown openedDropdown toggle onLogout =
    maybeUser
        |> Maybe.mapOrElse
            (\user ->
                Dropdown.dropdown { id = profileDropdown, direction = BottomLeft, isOpen = openedDropdown == profileDropdown }
                    (\m ->
                        button [ type_ "button", id m.id, onClick (toggle profileDropdown), css [ "mx-1 flex-shrink-0 p-0.5 rounded-full flex text-sm", hover [ "animate-jello-h" ], focus_ring_offset_600 Tw.primary ], ariaExpanded m.isOpen, ariaHaspopup "true" ]
                            [ span [ css [ "sr-only" ] ] [ text "Open user menu" ]
                            , img [ css [ "rounded-full h-7 w-7" ], src (user |> User.avatar), alt user.name, width 28, height 28 ] []
                            ]
                            |> Tooltip.bl user.name
                    )
                    (\_ ->
                        div []
                            [ ContextMenu.link { url = Route.toHref Route.Profile, text = "Your profile" }

                            --, ContextMenu.link { url = "#", text = "Settings" }
                            , ContextMenu.btn "" onLogout [ text "Logout" ]
                            ]
                    )
            )
            (a [ href (Router.login currentUrl), css [ "mx-1 flex-shrink-0 bg-primary-600 p-1 rounded-full text-primary-200", hover [ "text-white animate-flip-h" ], focus_ring_offset_600 Tw.primary ] ]
                [ span [ class "sr-only" ] [ text "Sign in" ]
                , Icon.outline Icon.User ""
                ]
                |> Tooltip.bl "Sign in"
            )


viewHeader : List (Html msg) -> Html msg
viewHeader content =
    header [ css [ "py-10" ] ]
        [ div [ css [ "max-w-7xl mx-auto px-4", sm [ "px-6" ], lg [ "px-8" ] ] ]
            [ h1 [ css [ "text-3xl font-bold text-white" ] ] content
            ]
        ]


viewFooter : Html msg
viewFooter =
    footer []
        [ div [ css [ "max-w-7xl mx-auto py-12 px-4", sm [ "px-6" ], md [ "flex items-center justify-between" ], lg [ "px-8" ] ] ]
            [ div [ css [ "mt-8", md [ "mt-0 order-1" ] ] ]
                [ p [ css [ "text-center text-base text-gray-400" ] ]
                    [ text "Azimutt is an "
                    , extLink Conf.constants.azimuttGithub [ css [ "link" ] ] [ text "Open source" ]
                    , text " tool written with love in "
                    , extLink "https://elm-lang.org" [ css [ "link" ] ] [ text "Elm" ]
                    , text ". We always look for "
                    , extLink Conf.constants.azimuttFeatureRequests [ css [ "link" ] ] [ text "feedback" ]
                    , text " and will happily discuss your use cases to make it evolve."
                    ]
                ]
            ]
        ]
