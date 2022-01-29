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
import Html exposing (Html, div)
import Html.Attributes exposing (class, id)
import Html.Styled as S
import Html.Styled.Attributes as SA
import Libs.Html.Styled as S
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


publicHeader : S.Html msg
publicHeader =
    Header.rightLinksWhite
        { brand = { img = { src = "/logo.png", alt = "Azimutt" }, link = { url = Route.toHref Route.Home_, text = "Azimutt" } }
        , links =
            [ { url = Route.toHref Route.Blog, content = [ S.text "Blog" ], external = False }
            , { url = Conf.constants.azimuttDiscussions, content = [ S.text "Discussions" ], external = True }
            , { url = Conf.constants.azimuttRoadmap, content = [ S.text "Roadmap" ], external = True }
            , { url = Conf.constants.azimuttGithub, content = [ S.text "Source code" ], external = True }
            , { url = Conf.constants.azimuttBugReport, content = [ S.text "Bug reports" ], external = True }
            , { url = Conf.constants.azimuttTwitter, content = [ Icon.twitter [], S.span [ SA.css [ Tw.sr_only ] ] [ S.text "Twitter" ] ], external = True }
            ]
        }


newsletterSection : S.Html msg
newsletterSection =
    Newsletter.basicSlice
        { form = Conf.newsletter |> (\n -> { n | cta = "Get onboard" })
        , title = "Sign up for Azimutt newsletter"
        , description = "Stay in touch with Azimutt news, features, articles or offers, directly in your mail box. Once a week at most, no spam guarantee."
        , legalText = []
        }


publicFooter : S.Html msg
publicFooter =
    Footer.slice


appShell :
    (Link -> msg)
    -> msg
    -> { x | selectedMenu : String, mobileMenuOpen : Bool }
    -> List (S.Html msg)
    -> List (S.Html msg)
    -> List (S.Html msg)
    -> List (S.Html msg)
appShell onNavigationClick onMobileMenuClick model title content footer =
    [ Global.global Tw.globalStyles
    , Global.global [ Global.selector "html" [ Tw.h_full, Tw.bg_gray_100 ], Global.selector "body" [ Tw.h_full ] ]
    , Styles.global
    , S.div [ SA.css [ Color.bg Conf.theme.color 600, Tw.pb_32 ] ]
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
    , S.div [ SA.css [ Tw.neg_mt_32 ] ]
        [ S.main_ [ SA.css [ Tw.max_w_7xl, Tw.mx_auto, Tw.pb_12, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_6 ] ] ]
            [ S.div [ SA.css [ Tw.bg_white, Tw.rounded_lg, Tw.shadow ] ] content
            ]
        ]
    ]
        ++ (viewOldApp :: footer)


viewHeader : List (S.Html msg) -> S.Html msg
viewHeader content =
    S.header [ SA.css [ Tw.py_10 ] ]
        [ S.div [ SA.css [ Tw.max_w_7xl, Tw.mx_auto, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_6 ] ] ]
            [ S.h1 [ SA.css [ Tw.text_3xl, Tw.font_bold, Tw.text_white ] ] content
            ]
        ]


viewOldApp : S.Html msg
viewOldApp =
    S.footer []
        [ S.div [ SA.css [ Tw.max_w_7xl, Tw.mx_auto, Tw.py_12, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.md [ Tw.flex, Tw.items_center, Tw.justify_between ], Bp.sm [ Tw.px_6 ] ] ]
            [ S.div [ SA.css [ Tw.mt_8, Bp.md [ Tw.mt_0, Tw.order_1 ] ] ]
                [ S.p [ SA.css [ Tw.text_center, Tw.text_base, Tw.text_gray_400 ] ]
                    [ S.text "This new Azimutt version is in trial, please give "
                    , S.extLink Conf.constants.azimuttBugReport [ SA.css [ Tu.link ] ] [ S.text "any feedback" ]
                    , S.text " you may have. You can still access the previous version "
                    , S.a [ SA.href (Route.toHref Route.App), SA.css [ Tu.link ] ] [ S.text "here" ]
                    , S.text "."
                    ]
                ]
            ]
        ]
