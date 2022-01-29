module Components.Slices.Blog exposing (Article, Model, Subscribe, article, articleList, doc)

import Components.Slices.Newsletter as Newsletter
import Css
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, div, form, h2, p, text, time)
import Html.Styled.Attributes exposing (css, datetime, href)
import Libs.DateTime as DateTime
import Libs.Maybe as M
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw
import Time


type alias Model =
    { title : String
    , headline : String
    , newsletter : Maybe Newsletter.Form
    , articles : List Article
    }


type alias Subscribe =
    { placeholder : String, cta : String }


type alias Article =
    { date : Time.Posix
    , link : String
    , title : String
    , excerpt : String
    }


articleList : Model -> Html msg
articleList model =
    div [ css [ Tw.bg_white, Tw.pt_16, Tw.pb_20, Tw.px_4, Bp.lg [ Tw.pt_24, Tw.pb_28, Tw.px_8 ], Bp.sm [ Tw.px_6 ] ] ]
        [ div [ css [ Tw.relative, Tw.max_w_lg, Tw.mx_auto, Tw.divide_y_2, Tw.divide_gray_200, Bp.lg [ Tw.max_w_7xl ] ] ]
            [ div []
                [ h2 [ css [ Tw.text_3xl, Tw.tracking_tight, Tw.font_extrabold, Tw.text_gray_900, Bp.sm [ Tw.text_4xl ] ] ] [ text model.title ]
                , div [ css [ Tw.mt_3, Bp.lg [ Tw.grid, Tw.grid_cols_2, Tw.gap_5, Tw.items_center ], Bp.sm [ Tw.mt_4 ] ] ]
                    ([ p [ css [ Tw.text_xl, Tw.text_gray_500 ] ] [ text model.headline ]
                     ]
                        ++ (model.newsletter |> M.mapOrElse (\form -> [ Newsletter.small form ]) [])
                    )
                ]
            , div [ css [ Tw.mt_6, Tw.pt_10, Tw.grid, Tw.gap_16, Bp.lg [ Tw.grid_cols_2, Tw.gap_x_5, Tw.gap_y_12 ] ] ] (model.articles |> List.map articleItem)
            ]
        ]


articleItem : Article -> Html msg
articleItem model =
    div []
        [ p [ css [ Tw.text_sm, Tw.text_gray_500 ] ]
            [ time [ datetime (model.date |> DateTime.formatUtc "yyyy-MM-dd") ] [ text (model.date |> DateTime.formatUtc "MMM dd, yyyy") ] ]
        , a [ href model.link, css [ Tw.mt_2, Tw.block ] ]
            [ p [ css [ Tw.text_xl, Tw.font_semibold, Tw.text_gray_900 ] ] [ text model.title ]
            , p [ css [ Tw.mt_3, Tw.text_base, Tw.text_gray_500 ] ] [ text model.excerpt ]
            ]
        , div [ css [ Tw.mt_3 ] ]
            [ a [ href model.link, css [ Tw.text_base, Tw.font_semibold, Tw.text_indigo_600, Css.hover [ Tw.text_indigo_500 ] ] ] [ text "Read full story" ] ]
        ]


article : Article -> Html msg
article model =
    div []
        [ time [ datetime (model.date |> DateTime.formatUtc "yyyy-MM-dd"), css [ Tw.uppercase, Tw.text_xs, Tw.text_gray_500, Tw.font_bold ] ] [ text (model.date |> DateTime.formatUtc "MMM dd, yyyy") ]
        , h2 [ css [ Tw.mt_1, Tw.text_2xl, Tw.tracking_tight, Tw.font_extrabold, Tw.text_gray_900, Bp.md [ Tw.text_3xl ], Bp.sm [ Tw.leading_none ] ] ]
            [ a [ href model.link ] [ text model.title ] ]
        , div [ css [ Tw.mt_6 ] ]
            [ p [] [ text model.excerpt ] ]
        , div [ css [ Tw.mt_10 ] ]
            [ a [ css [ Tw.text_indigo_600, Tw.uppercase, Tw.text_sm, Tw.tracking_wide, Tw.font_black ], href model.link ] [ text "Read full story →" ] ]
        ]



-- DOCUMENTATION


articleDoc : Article
articleDoc =
    { date = "2020-03-16" |> DateTime.unsafeParse
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
        , { date = "2020-03-10" |> DateTime.unsafeParse
          , link = "#"
          , title = "How to use search engine optimization to drive sales"
          , excerpt = "Optio cum necessitatibus dolor voluptatum provident commodi et. Qui aperiam fugiat nemo cumque."
          }
        , { date = "2020-02-12" |> DateTime.unsafeParse
          , link = "#"
          , title = "Improve your customer experience"
          , excerpt = "Cupiditate maiores ullam eveniet adipisci in doloribus nulla minus. Voluptas iusto libero adipisci rem et corporis."
          }
        , { date = "2020-01-29" |> DateTime.unsafeParse
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
