module Components.Slices.Blog exposing (Article, Model, Subscribe, articleList, doc)

import Css exposing (focus, hover)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, button, div, form, h2, input, label, p, text, time)
import Html.Styled.Attributes exposing (attribute, css, datetime, for, href, id, name, placeholder, required, type_)
import Tailwind.Breakpoints exposing (lg, sm)
import Tailwind.Utilities exposing (appearance_none, bg_indigo_600, bg_indigo_700, bg_white, block, border, border_gray_300, border_indigo_500, border_transparent, divide_gray_200, divide_y_2, flex, flex_col, flex_row, flex_shrink_0, font_extrabold, font_medium, font_semibold, gap_16, gap_5, grid, grid_cols_2, inline_flex, items_center, justify_center, justify_end, max_w_7xl, max_w_lg, max_w_xs, ml_3, mt_0, mt_2, mt_3, mt_4, mt_6, mx_auto, outline_none, pb_20, pb_28, placeholder_gray_500, pt_10, pt_16, pt_24, px_4, px_6, px_8, py_2, relative, ring_2, ring_indigo_500, ring_offset_2, rounded_md, shadow_sm, sr_only, text_3xl, text_4xl, text_base, text_gray_500, text_gray_900, text_indigo_500, text_indigo_600, text_sm, text_white, text_xl, tracking_tight, w_auto, w_full)


type alias Model =
    { title : String
    , headline : String
    , subscribe : Maybe Subscribe
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
                        ++ (model.subscribe
                                |> Maybe.map
                                    (\sub ->
                                        [ form [ css [ mt_6, flex, flex_col, lg [ mt_0, justify_end ], sm [ flex_row ] ] ]
                                            [ div []
                                                [ label [ for "email-address", css [ sr_only ] ] [ text sub.placeholder ]
                                                , input [ id "email-address", name "email-address", type_ "email", attribute "autocomplete" "email", required True, css [ appearance_none, w_full, px_4, py_2, border, border_gray_300, text_base, rounded_md, text_gray_900, bg_white, placeholder_gray_500, focus [ outline_none, ring_indigo_500, border_indigo_500 ], lg [ max_w_xs ] ], placeholder sub.placeholder ] []
                                                ]
                                            , div [ css [ mt_2, flex_shrink_0, w_full, flex, rounded_md, shadow_sm, sm [ mt_0, ml_3, w_auto, inline_flex ] ] ]
                                                [ button [ type_ "button", css [ w_full, bg_indigo_600, px_4, py_2, border, border_transparent, rounded_md, flex, items_center, justify_center, text_base, font_medium, text_white, focus [ outline_none, ring_2, ring_offset_2, ring_indigo_500 ], hover [ bg_indigo_700 ], sm [ w_auto, inline_flex ] ] ]
                                                    [ text sub.cta ]
                                                ]
                                            ]
                                        ]
                                    )
                                |> Maybe.withDefault []
                           )
                    )
                ]
            , div [ css [ mt_6, pt_10, grid, gap_16 ] ] (model.articles |> List.map articleItem)
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


modelDoc : Model
modelDoc =
    { title = "Press"
    , headline = "Get weekly articles in your inbox on how to grow your business."
    , subscribe = Just { placeholder = "Enter your email", cta = "Notify me" }
    , articles =
        [ { date = { label = "Mar 16, 2020", formatted = "2020-03-16" }
          , link = "#"
          , title = "Boost your conversion rate"
          , excerpt = "Illo sint voluptas. Error voluptates culpa eligendi. Hic vel totam vitae illo. Non aliquid explicabo necessitatibus unde. Sed exercitationem placeat consectetur nulla deserunt vel. Iusto corrupti dicta."
          }
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
            ]
