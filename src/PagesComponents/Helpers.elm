module PagesComponents.Helpers exposing (newsletterSection, publicFooter, publicHeader, root, rootStyled)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Organisms.Footer as Footer
import Components.Organisms.Header as Header
import Components.Slices.Newsletter as Newsletter
import Conf exposing (constants, newsletterConf)
import Gen.Route as Route
import Html exposing (Html, div)
import Html.Attributes exposing (class, id)
import Html.Styled exposing (span, text)
import Html.Styled.Attributes exposing (css)
import Tailwind.Utilities exposing (sr_only)


root : List (Html msg) -> List (Html msg)
root children =
    children ++ [ viewToasts ]


viewToasts : Html msg
viewToasts =
    div [ id "toast-container", class "toast-container position-fixed bottom-0 start-0 p-2" ] []


rootStyled : List (Html.Styled.Html msg) -> List (Html.Styled.Html msg)
rootStyled children =
    children ++ [ viewToastsStyled ]


viewToastsStyled : Html.Styled.Html msg
viewToastsStyled =
    Html.Styled.div [ Html.Styled.Attributes.id "toast-container", Html.Styled.Attributes.class "toast-container position-fixed bottom-0 start-0 p-2" ] []


publicHeader : Html.Styled.Html msg
publicHeader =
    Header.rightLinksWhite
        { brand = { img = { src = "/logo.png", alt = "Azimutt" }, link = { url = Route.toHref Route.Home_, text = "Azimutt" } }
        , links =
            [ { url = Route.toHref Route.Blog, content = [ text "Blog" ], external = False }
            , { url = constants.azimuttGithub ++ "/discussions", content = [ text "Discussions" ], external = True }
            , { url = constants.azimuttGithub ++ "/projects/1", content = [ text "Roadmap" ], external = True }
            , { url = constants.azimuttGithub, content = [ text "Source code" ], external = True }
            , { url = constants.azimuttGithub ++ "/issues", content = [ text "Bug reports" ], external = True }
            , { url = constants.azimuttTwitter, content = [ Icon.view Twitter [], span [ css [ sr_only ] ] [ text "Twitter" ] ], external = True }
            ]
        }


newsletterSection : Html.Styled.Html msg
newsletterSection =
    Newsletter.basicSlice
        { form = { newsletterConf | cta = "Get onboard" }
        , title = "Sign up for Azimutt newsletter"
        , description = "Stay in touch with Azimutt news, features, articles or offers, directly in your mail box. Once a week at most, no spam guarantee."
        , legalText = []
        }


publicFooter : Html.Styled.Html msg
publicFooter =
    Footer.slice
