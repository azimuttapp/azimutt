module PagesComponents.Blog.View exposing (viewBlog)

import Components.Slices.Blog as Blog
import Components.Slices.Newsletter as Newsletter
import Conf
import Css
import Css.Global as Global
import Html.Styled exposing (Html, div, h1, hr, p, text)
import Html.Styled.Attributes exposing (css, style)
import Libs.Html.Styled exposing (extLink)
import PagesComponents.Blog.Models exposing (Model)
import PagesComponents.Helpers as Helpers
import Tailwind.Utilities as Tw


viewBlog : Model -> List (Html msg)
viewBlog model =
    [ Global.global Tw.globalStyles
    , Helpers.publicHeader
    , div [ css [ Tw.mt_24, Tw.max_w_prose, Tw.mx_auto, Tw.text_center ] ]
        [ h1 [ css [ Tw.text_4xl, Tw.font_black ] ]
            [ text "Azimutt blog" ]
        , p [ css [ Tw.text_lg, Tw.mt_6 ] ]
            [ text "Hi! We are "
            , extLink "https://twitter.com/sbouaked" [ css [ Tw.text_indigo_600, Css.hover [ Tw.underline ] ] ] [ text "Samir" ]
            , text " and "
            , extLink "https://twitter.com/loicknuchel" [ css [ Tw.text_indigo_600, Css.hover [ Tw.underline ] ] ] [ text "Loïc" ]
            , text ". We're building an application to empower developers understanding their relational databases. You can read about how we build it and how to use it on this blog."
            ]
        ]
    , div [ css [ Tw.mt_12 ] ] [ Newsletter.centered Conf.newsletter ]
    , hr [ css [ Tw.w_full, Tw.bg_gray_100, Tw.my_12 ], style "height" "1px" ] []
    , div [ css [ Tw.mt_16, Tw.mb_24, Tw.max_w_prose, Tw.mx_auto ] ] (model.articles |> List.map Tuple.second |> List.map Blog.article |> List.intersperse (hr [ css [ Tw.w_full, Tw.bg_gray_100, Tw.my_12 ], style "height" "1px" ] []))

    -- add it when out of initial page, Helpers.newsletterSection
    , Helpers.publicFooter
    ]
