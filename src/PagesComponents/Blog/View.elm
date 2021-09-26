module PagesComponents.Blog.View exposing (viewBlog)

import Components.Slices.Blog as Blog
import Css.Global as Global
import Gen.Route as Route
import Html.Styled exposing (Html)
import PagesComponents.Blog.Models exposing (Model)
import PagesComponents.Helpers as Helpers
import Tailwind.Utilities exposing (globalStyles)


viewBlog : Model -> List (Html msg)
viewBlog _ =
    [ Global.global globalStyles
    , Helpers.publicHeader
    , Blog.articleList
        { title = "Blog"
        , headline = "Get weekly articles in your inbox on how to grow your business."
        , subscribe = Nothing
        , articles =
            [ { date = { label = "Mar 16, 2020", formatted = "2020-03-16" }
              , link = Route.toHref (Route.Blog__Slug_ { slug = "sample" })
              , title = "Boost your conversion rate"
              , excerpt = "Illo sint voluptas. Error voluptates culpa eligendi. Hic vel totam vitae illo. Non aliquid explicabo necessitatibus unde. Sed exercitationem placeat consectetur nulla deserunt vel. Iusto corrupti dicta."
              }
            , { date = { label = "Mar 16, 2020", formatted = "2020-03-16" }
              , link = Route.toHref (Route.Blog__Slug_ { slug = "sample" })
              , title = "Boost your conversion rate"
              , excerpt = "Illo sint voluptas. Error voluptates culpa eligendi. Hic vel totam vitae illo. Non aliquid explicabo necessitatibus unde. Sed exercitationem placeat consectetur nulla deserunt vel. Iusto corrupti dicta."
              }
            , { date = { label = "Mar 16, 2020", formatted = "2020-03-16" }
              , link = Route.toHref (Route.Blog__Slug_ { slug = "sample" })
              , title = "Boost your conversion rate"
              , excerpt = "Illo sint voluptas. Error voluptates culpa eligendi. Hic vel totam vitae illo. Non aliquid explicabo necessitatibus unde. Sed exercitationem placeat consectetur nulla deserunt vel. Iusto corrupti dicta."
              }
            , { date = { label = "Mar 16, 2020", formatted = "2020-03-16" }
              , link = Route.toHref (Route.Blog__Slug_ { slug = "sample" })
              , title = "Boost your conversion rate"
              , excerpt = "Illo sint voluptas. Error voluptates culpa eligendi. Hic vel totam vitae illo. Non aliquid explicabo necessitatibus unde. Sed exercitationem placeat consectetur nulla deserunt vel. Iusto corrupti dicta."
              }
            ]
        }
    , Helpers.publicFooter
    ]
