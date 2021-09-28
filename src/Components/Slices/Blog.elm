module Components.Slices.Blog exposing (Article, Model, Subscribe, article, articleList, doc)

import Components.Slices.Newsletter as Newsletter
import Css exposing (hover)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, div, form, h2, p, text, time)
import Html.Styled.Attributes exposing (css, datetime, href)
import Tailwind.Breakpoints exposing (lg, md, sm)
import Tailwind.Utilities exposing (bg_white, block, divide_gray_200, divide_y_2, font_black, font_bold, font_extrabold, font_semibold, gap_16, gap_5, gap_x_5, gap_y_12, grid, grid_cols_2, items_center, leading_none, max_w_7xl, max_w_lg, mt_1, mt_10, mt_2, mt_3, mt_4, mt_6, mx_auto, pb_20, pb_28, pt_10, pt_16, pt_24, px_4, px_6, px_8, relative, text_2xl, text_3xl, text_4xl, text_base, text_gray_500, text_gray_900, text_indigo_500, text_indigo_600, text_sm, text_xl, text_xs, tracking_tight, tracking_wide, uppercase)


type alias Model =
    { title : String
    , headline : String
    , newsletter : Maybe Newsletter.Form
    , articles : List Article
    }


type alias Subscribe =
    { placeholder : String, cta : String }


type alias Article =
    { date : { label : String, formatted : String }
    , link : String
    , title : String
    , excerpt : String
    }


articleList : Model -> Html msg
articleList model =
    div [ css [ bg_white, pt_16, pb_20, px_4, lg [ pt_24, pb_28, px_8 ], sm [ px_6 ] ] ]
        [ div [ css [ relative, max_w_lg, mx_auto, divide_y_2, divide_gray_200, lg [ max_w_7xl ] ] ]
            [ div []
                [ h2 [ css [ text_3xl, tracking_tight, font_extrabold, text_gray_900, sm [ text_4xl ] ] ] [ text model.title ]
                , div [ css [ mt_3, lg [ grid, grid_cols_2, gap_5, items_center ], sm [ mt_4 ] ] ]
                    ([ p [ css [ text_xl, text_gray_500 ] ] [ text model.headline ]
                     ]
                        ++ (model.newsletter |> Maybe.map (\form -> [ Newsletter.small form ]) |> Maybe.withDefault [])
                    )
                ]
            , div [ css [ mt_6, pt_10, grid, gap_16, lg [ grid_cols_2, gap_x_5, gap_y_12 ] ] ] (model.articles |> List.map articleItem)
            ]
        ]


articleItem : Article -> Html msg
articleItem model =
    div []
        [ p [ css [ text_sm, text_gray_500 ] ]
            [ time [ datetime model.date.formatted ] [ text model.date.label ] ]
        , a [ href model.link, css [ mt_2, block ] ]
            [ p [ css [ text_xl, font_semibold, text_gray_900 ] ] [ text model.title ]
            , p [ css [ mt_3, text_base, text_gray_500 ] ] [ text model.excerpt ]
            ]
        , div [ css [ mt_3 ] ]
            [ a [ href model.link, css [ text_base, font_semibold, text_indigo_600, hover [ text_indigo_500 ] ] ] [ text "Read full story" ] ]
        ]


article : Article -> Html msg
article model =
    div []
        [ time [ datetime model.date.formatted, css [ uppercase, text_xs, text_gray_500, font_bold ] ] [ text model.date.label ]
        , h2 [ css [ mt_1, text_2xl, tracking_tight, font_extrabold, text_gray_900, md [ text_3xl ], sm [ leading_none ] ] ]
            [ a [ href model.link ] [ text model.title ] ]
        , div [ css [ mt_6 ] ]
            [ p [] [ text model.excerpt ] ]
        , div [ css [ mt_10 ] ]
            [ a [ css [ text_indigo_600, uppercase, text_sm, tracking_wide, font_black ], href model.link ] [ text "Read full story →" ] ]
        ]



-- DOCUMENTATION


articleDoc : Article
articleDoc =
    { date = { label = "Mar 16, 2020", formatted = "2020-03-16" }
    , link = "#"
    , title = "Boost your conversion rate"
    , excerpt = "Illo sint voluptas. Error voluptates culpa eligendi. Hic vel totam vitae illo. Non aliquid explicabo necessitatibus unde. Sed exercitationem placeat consectetur nulla deserunt vel. Iusto corrupti dicta."
    }


modelDoc : Model
modelDoc =
    { title = "Press"
    , headline = "Get weekly articles in your inbox on how to grow your business."
    , newsletter = Just Newsletter.formDoc
    , articles =
        [ articleDoc
        , { date = { label = "Mar 10, 2020", formatted = "2020-03-10" }
          , link = "#"
          , title = "How to use search engine optimization to drive sales"
          , excerpt = "Optio cum necessitatibus dolor voluptatum provident commodi et. Qui aperiam fugiat nemo cumque."
          }
        , { date = { label = "Feb 12, 2020", formatted = "2020-02-12" }
          , link = "#"
          , title = "Improve your customer experience"
          , excerpt = "Cupiditate maiores ullam eveniet adipisci in doloribus nulla minus. Voluptas iusto libero adipisci rem et corporis."
          }
        , { date = { label = "Jan 29, 2020", formatted = "2020-01-29" }
          , link = "#"
          , title = "Writing effective landing page copy"
          , excerpt = "Ipsum voluptates quia doloremque culpa qui eius. Id qui id officia molestias quaerat deleniti. Qui facere numquam autem libero quae cupiditate asperiores vitae cupiditate. Cumque id deleniti explicabo."
          }
        ]
    }


doc : Chapter x
doc =
    chapter "Blog"
        |> renderComponentList
            [ ( "articleList", articleList modelDoc )
            , ( "article", article articleDoc )
            ]
