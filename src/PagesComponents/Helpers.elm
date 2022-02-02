module PagesComponents.Helpers exposing (appShell, newsletterSection, publicFooter, publicHeader, root)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Styles as Styles
import Components.Organisms.Footer as Footer
import Components.Organisms.Header as Header
import Components.Organisms.Navbar as Navbar
import Components.Slices.Newsletter as Newsletter
import Conf
import Css.Global as Global
import Gen.Route as Route
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class, id)
import Html.Styled as Styled exposing (fromUnstyled)
import Html.Styled.Attributes as Styled
import Libs.Html.Styled as Styled
import Libs.Models exposing (Link)
import Libs.Models.Color as Color
import Libs.Tailwind.Utilities as Tu
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


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
    -> List (Styled.Html msg)
    -> List (Styled.Html msg)
    -> List (Styled.Html msg)
    -> List (Styled.Html msg)
appShell onNavigationClick onMobileMenuClick model title content footer =
    [ Global.global Tw.globalStyles
    , Global.global [ Global.selector "html" [ Tw.h_full, Tw.bg_gray_100 ], Global.selector "body" [ Tw.h_full ] ]
    , Styles.global
    , Styled.div [ Styled.css [ Color.bg Conf.theme.color 600, Tw.pb_32 ] ]
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
            |> fromUnstyled
        , viewHeader title
        ]
    , Styled.div [ Styled.css [ Tw.neg_mt_32 ] ]
        [ Styled.main_ [ Styled.css [ Tw.max_w_7xl, Tw.mx_auto, Tw.pb_12, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_6 ] ] ]
            [ Styled.div [ Styled.css [ Tw.bg_white, Tw.rounded_lg, Tw.shadow ] ] content
            ]
        ]
    ]
        ++ (viewOldApp :: footer)


viewHeader : List (Styled.Html msg) -> Styled.Html msg
viewHeader content =
    Styled.header [ Styled.css [ Tw.py_10 ] ]
        [ Styled.div [ Styled.css [ Tw.max_w_7xl, Tw.mx_auto, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_6 ] ] ]
            [ Styled.h1 [ Styled.css [ Tw.text_3xl, Tw.font_bold, Tw.text_white ] ] content
            ]
        ]


viewOldApp : Styled.Html msg
viewOldApp =
    Styled.footer []
        [ Styled.div [ Styled.css [ Tw.max_w_7xl, Tw.mx_auto, Tw.py_12, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.md [ Tw.flex, Tw.items_center, Tw.justify_between ], Bp.sm [ Tw.px_6 ] ] ]
            [ Styled.div [ Styled.css [ Tw.mt_8, Bp.md [ Tw.mt_0, Tw.order_1 ] ] ]
                [ Styled.p [ Styled.css [ Tw.text_center, Tw.text_base, Tw.text_gray_400 ] ]
                    [ Styled.text "This new Azimutt version is in trial, please give "
                    , Styled.extLink Conf.constants.azimuttBugReport [ Styled.css [ Tu.link ] ] [ Styled.text "any feedback" ]
                    , Styled.text " you may have. You can still access the previous version "
                    , Styled.a [ Styled.href (Route.toHref Route.App), Styled.css [ Tu.link ] ] [ Styled.text "here" ]
                    , Styled.text "."
                    ]
                ]
            ]
        ]
