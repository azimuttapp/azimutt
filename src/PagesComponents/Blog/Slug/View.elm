module PagesComponents.Blog.Slug.View exposing (viewArticle)

import Components.Organisms.Header as Header
import Css.Global as Global
import Gen.Route as Route
import Html.Styled exposing (Html, a, div, text)
import Html.Styled.Attributes exposing (href)
import PagesComponents.Blog.Slug.Models exposing (Model)
import Tailwind.Utilities exposing (globalStyles)


viewArticle : Model -> List (Html msg)
viewArticle _ =
    [ Global.global globalStyles
    , Header.leftLinksIndigo
        { brand = { img = { src = "https://tailwindui.com/img/logos/workflow-mark.svg?color=white", alt = "" }, link = { url = Route.toHref Route.Home_, text = "Workflow" } }
        , primary = { url = "#", text = "Sign up" }
        , secondary = { url = "#", text = "Sign in" }
        , links =
            [ { url = "#", text = "Solutions" }
            , { url = "#", text = "Pricing" }
            , { url = "#", text = "Docs" }
            , { url = "#", text = "Company" }
            ]
        }
    , div [] [ a [ href (Route.toHref Route.Blog) ] [ text "Back to blog" ] ]
    ]
