module PagesComponents.Blog.View exposing (viewBlog)

import Components.Slices.Blog as Blog
import Conf exposing (newsletterConf)
import Css.Global as Global
import Html.Styled exposing (Html)
import PagesComponents.Blog.Models exposing (Model)
import PagesComponents.Helpers as Helpers
import Tailwind.Utilities exposing (globalStyles)


viewBlog : Model -> List (Html msg)
viewBlog model =
    [ Global.global globalStyles
    , Helpers.publicHeader
    , Blog.articleList
        { title = "Blog"
        , headline = "Get weekly articles in your inbox on how to grow your business."
        , newsletter = Just newsletterConf
        , articles = model.articles
        }
    , Helpers.newsletterSection
    , Helpers.publicFooter
    ]
