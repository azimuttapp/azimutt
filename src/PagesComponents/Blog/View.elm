module PagesComponents.Blog.View exposing (viewBlog)

import Components.Slices.Blog as Blog
import Components.Slices.Newsletter as Newsletter
import Conf exposing (newsletterConf)
import Css exposing (hover)
import Css.Global as Global
import Html.Styled exposing (Html, div, h1, hr, p, text)
import Html.Styled.Attributes exposing (css, style)
import Libs.Html.Styled exposing (extLink)
import PagesComponents.Blog.Models exposing (Model)
import PagesComponents.Helpers as Helpers
import Tailwind.Utilities exposing (bg_gray_100, font_black, globalStyles, max_w_prose, mb_24, mt_12, mt_16, mt_24, mt_6, mx_auto, my_12, text_4xl, text_center, text_indigo_600, text_lg, underline, w_full)


viewBlog : Model -> List (Html msg)
viewBlog model =
    [ Global.global globalStyles
    , Helpers.publicHeader
    , div [ css [ mt_24, max_w_prose, mx_auto, text_center ] ]
        [ h1 [ css [ text_4xl, font_black ] ]
            [ text "Azimutt Blog" ]
        , p [ css [ text_lg, mt_6 ] ]
            [ text "Hi! We are "
            , extLink "https://twitter.com/sbouaked" [ css [ text_indigo_600, Css.hover [ underline ] ] ] [ text "Samir" ]
            , text " and "
            , extLink "https://twitter.com/loicknuchel" [ css [ text_indigo_600, hover [ underline ] ] ] [ text "Loïc" ]
            , text ". We're building an application to empower developers understanding their relational databases. You can read about how we build it and how to use it on this blog."
            ]
        ]
    , div [ css [ mt_12 ] ] [ Newsletter.centered newsletterConf ]
    , hr [ css [ w_full, bg_gray_100, my_12 ], style "height" "1px" ] []
    , div [ css [ mt_16, mb_24, max_w_prose, mx_auto ] ] (model.articles |> List.map Blog.article |> List.intersperse (hr [ css [ w_full, bg_gray_100, my_12 ], style "height" "1px" ] []))

    -- add it when out of initial page, Helpers.newsletterSection
    , Helpers.publicFooter
    ]
