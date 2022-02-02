module PagesComponents.Helpers exposing (appShell, newsletterSection, publicFooter, publicHeader, root)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Organisms.Footer as Footer
import Components.Organisms.Header as Header
import Components.Organisms.Navbar as Navbar
import Components.Slices.Newsletter as Newsletter
import Conf
import Gen.Route as Route
import Html exposing (Html, a, div, footer, h1, header, main_, p, span, text)
import Html.Attributes exposing (class, href, id)
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css)
import Libs.Models exposing (Link)
import Libs.Tailwind exposing (bg_600, lg, md, sm)


root : List (Html msg) -> List (Html msg)
root children =
    children ++ [ viewToasts ]


viewToasts : Html msg
viewToasts =
    div [ id "toast-container", class "toast-container position-fixed bottom-0 start-0 p-2" ] []


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
    (Link -> msg)
    -> msg
    -> { x | selectedMenu : String, mobileMenuOpen : Bool }
    -> List (Html msg)
    -> List (Html msg)
    -> List (Html msg)
    -> List (Html msg)
appShell onNavigationClick onMobileMenuClick model title content footer =
    [ div [ css [ "pb-32", bg_600 Conf.theme.color ] ]
        [ Navbar.admin Conf.theme
            { brand = { img = { src = "/logo.png", alt = "Azimutt" }, link = { url = Route.toHref Route.Home_, text = "Azimutt" } }
            , navigation =
                { links = [ { url = Route.toHref Route.Projects, text = "Dashboard" } ]
                , onClick = onNavigationClick
                }
            , search = Nothing
            , notifications = Nothing
            , profile = Nothing
            , mobileMenu = { id = "mobile-menu", onClick = onMobileMenuClick }
            }
            { selectedMenu = model.selectedMenu
            , mobileMenuOpen = model.mobileMenuOpen
            , profileOpen = False
            }
        , viewHeader title
        ]
    , div [ css [ "-mt-32" ] ]
        [ main_ [ css [ "max-w-7xl mx-auto pb-12 px-4", lg "px-8", sm "px-6" ] ]
            [ div [ css [ "bg-white rounded-lg shadow" ] ] content
            ]
        ]
    ]
        ++ (viewOldApp :: footer)


viewHeader : List (Html msg) -> Html msg
viewHeader content =
    header [ css [ "py-10" ] ]
        [ div [ css [ "max-w-7xl mx-auto px-4", lg "px-8", sm "px-6" ] ]
            [ h1 [ css [ "text-3xl font-bold text-white" ] ] content
            ]
        ]


viewOldApp : Html msg
viewOldApp =
    footer []
        [ div [ css [ "max-w-7xl mx-auto py-12 px-4", lg "px-8", md "flex items-center justify-between", sm "px-6" ] ]
            [ div [ css [ "mt-8", md "mt-0 order-1" ] ]
                [ p [ css [ "text-center text-base text-gray-400" ] ]
                    [ text "This new Azimutt version is in trial, please give "
                    , extLink Conf.constants.azimuttBugReport [ css [ "tw-link" ] ] [ text "any feedback" ]
                    , text " you may have. You can still access the previous version "
                    , a [ href (Route.toHref Route.App), css [ "tw-link" ] ] [ text "here" ]
                    , text "."
                    ]
                ]
            ]
        ]
