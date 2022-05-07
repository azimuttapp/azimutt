module PagesComponents.Helpers exposing (appShell, newsletterSection, publicFooter, publicHeader)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Organisms.Footer as Footer
import Components.Organisms.Header as Header
import Components.Organisms.Navbar as Navbar
import Components.Slices.Newsletter as Newsletter
import Conf
import Gen.Route as Route
import Html exposing (Html, div, footer, h1, header, main_, p, span, text)
import Html.Attributes exposing (class)
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css)
import Libs.Models exposing (Link)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind exposing (lg, md, sm)
import Models.User exposing (User(..))


publicHeader : Html msg
publicHeader =
    Header.rightLinksWhite
        { brand = { img = { src = "/logo.png", alt = "Azimutt" }, link = { url = Route.toHref Route.Home_, text = "Azimutt" } }
        , links =
            [ { url = Route.toHref Route.Blog, content = [ text "Blog" ], external = False }
            , { url = Conf.constants.azimuttDiscussions, content = [ text "Discussions" ], external = True }
            , { url = Conf.constants.azimuttRoadmap, content = [ text "Roadmap" ], external = True }
            , { url = Conf.constants.azimuttGithub, content = [ text "Source code" ], external = True }
            , { url = Conf.constants.azimuttBugReport, content = [ text "Bug reports" ], external = True }
            , { url = Conf.constants.azimuttTwitter, content = [ Icon.twitter "", span [ class "sr-only" ] [ text "Twitter" ] ], external = True }
            ]
        }


newsletterSection : Html msg
newsletterSection =
    Newsletter.basicSlice
        { form = Conf.newsletter |> (\n -> { n | cta = "Get onboard" })
        , title = "Sign up for Azimutt newsletter"
        , description = "Stay in touch with Azimutt news, features, articles or offers, directly in your mail box. Once a week at most, no spam guarantee."
        , legalText = []
        }


publicFooter : Html msg
publicFooter =
    Footer.slice


appShell :
    User
    -> (Link -> msg)
    -> (HtmlId -> msg)
    -> msg
    -> { x | selectedMenu : String, mobileMenuOpen : Bool, openedDropdown : HtmlId }
    -> List (Html msg)
    -> List (Html msg)
    -> List (Html msg)
    -> List (Html msg)
appShell user onNavigationClick onProfileClick onMobileMenuClick model title content footer =
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
            , notifications = Nothing
            , profile =
                case user of
                    Guest ->
                        Just
                            { id = profileDropdown
                            , avatar = "/assets/images/guest.png"
                            , firstName = "Guest"
                            , lastName = ""
                            , email = ""
                            , links =
                                [ { url = Route.toHref Route.Login, text = "Log in" }
                                , { url = Route.toHref Route.Login, text = "Sign in" }
                                ]
                            , onClick = onProfileClick "shell-profile"
                            }

                    Logged infos ->
                        Just
                            { id = profileDropdown
                            , avatar = infos.avatar
                            , firstName = infos.firstName
                            , lastName = infos.lastName
                            , email = infos.email
                            , links =
                                [ { url = "", text = "Your profile" }
                                , { url = "", text = "Settings" }
                                , { url = "", text = "Sign out" }
                                ]
                            , onClick = onProfileClick "shell-profile"
                            }
            , mobileMenu = { id = "mobile-menu", onClick = onMobileMenuClick }
            }
            { selectedMenu = model.selectedMenu
            , mobileMenuOpen = model.mobileMenuOpen
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
