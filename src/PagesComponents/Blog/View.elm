module PagesComponents.Blog.View exposing (viewBlog)

import Components.Slices.Navbar as Navbar
import Gen.Route as Route
import Html.Styled exposing (Html, a, div, text)
import Html.Styled.Attributes exposing (href)
import PagesComponents.Blog.Models exposing (Model)


viewBlog : Model -> List (Html msg)
viewBlog _ =
    [ Navbar.leftLinksIndigo
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
    , div [] [ a [ href (Route.toHref (Route.Blog__Slug_ { slug = "demo" })) ] [ text "See article!" ] ]
    ]
