module PagesComponents.Blog.Slug.View exposing (viewArticle)

import Css.Global as Global
import Gen.Route as Route
import Html.Styled exposing (Html, a, div, text)
import Html.Styled.Attributes exposing (href)
import PagesComponents.Blog.Slug.Models exposing (Model)
import PagesComponents.Helpers as Helpers
import Tailwind.Utilities exposing (globalStyles)


viewArticle : Model -> List (Html msg)
viewArticle _ =
    [ Global.global globalStyles
    , Helpers.publicHeader
    , div [] [ a [ href (Route.toHref Route.Blog) ] [ text "Back to blog" ] ]
    ]
