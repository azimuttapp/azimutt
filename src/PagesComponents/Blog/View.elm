module PagesComponents.Blog.View exposing (viewBlog)

import Css.Global as Global
import Gen.Route as Route
import Html.Styled exposing (Html, a, div, text)
import Html.Styled.Attributes exposing (href)
import PagesComponents.Blog.Models exposing (Model)
import PagesComponents.Helpers as Helpers
import Tailwind.Utilities exposing (globalStyles)


viewBlog : Model -> List (Html msg)
viewBlog _ =
    [ Global.global globalStyles
    , Helpers.publicHeader
    , div []
        [ a [ href (Route.toHref (Route.Blog__Slug_ { slug = "demo" })) ]
            [ text "See article!"
            ]
        ]
    ]
