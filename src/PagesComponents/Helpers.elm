module PagesComponents.Helpers exposing (publicFooter, publicHeader, root)

import Components.Atoms.Icon as Icon
import Components.Organisms.Footer as Footer
import Components.Organisms.Header as Header
import Conf exposing (constants)
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
    div [ id "toast-container", class "toast-container position-fixed bottom-0 end-0 p-3" ] []


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
            , { url = constants.azimuttTwitter, content = [ Icon.twitter [], span [ css [ sr_only ] ] [ text "Twitter" ] ], external = True }
            ]
        }


publicFooter : Html.Styled.Html msg
publicFooter =
    Footer.slice
