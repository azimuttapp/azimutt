module Components.Slices.Blog exposing (Article, Model, Subscribe, article, articleList, doc)

import Components.Slices.Newsletter as Newsletter
import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html exposing (Html, a, div, form, h2, p, text, time)
import Html.Attributes exposing (class, datetime, href)
import Libs.DateTime as DateTime
import Libs.Html.Attributes exposing (css)
import Libs.Maybe as M
import Libs.Tailwind exposing (hover, lg, md, sm)
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
    div [ css [ "bg-white pt-16 pb-20 px-4", sm [ "px-6" ], lg [ "pt-24 pb-28 px-8" ] ] ]
        [ div [ css [ "relative max-w-lg mx-auto divide-y-2 divide-gray-200", lg [ "max-w-7xl" ] ] ]
            [ div []
                [ h2 [ css [ "text-3xl tracking-tight font-extrabold text-gray-900", sm [ "text-4xl" ] ] ] [ text model.title ]
                , div [ css [ "mt-3", sm [ "mt-4" ], lg [ "grid grid-cols-2 gap-5 items-center" ] ] ]
                    ([ p [ class "text-xl text-gray-500" ] [ text model.headline ]
                     ]
                        ++ (model.newsletter |> M.mapOrElse (\form -> [ Newsletter.small form ]) [])
                    )
                ]
            , div [ css [ "mt-6 pt-10 grid gap-16", lg [ "grid-cols-2 gap-x-5 gap-y-12" ] ] ] (model.articles |> List.map articleItem)
            ]
        ]


articleItem : Article -> Html msg
articleItem model =
    div []
        [ p [ class "text-sm text-gray-500" ]
            [ time [ datetime (model.date |> DateTime.formatUtc "yyyy-MM-dd") ] [ text (model.date |> DateTime.formatUtc "MMM dd, yyyy") ] ]
        , a [ href model.link, class "mt-2 block" ]
            [ p [ class "text-xl font-semibold text-gray-900" ] [ text model.title ]
            , p [ class "mt-3 text-base text-gray-500" ] [ text model.excerpt ]
            ]
        , div [ class "mt-3" ]
            [ a [ href model.link, css [ "text-base font-semibold text-indigo-600", hover [ "text-indigo-500" ] ] ] [ text "Read full story" ] ]
        ]


article : Article -> Html msg
article model =
    div []
        [ time [ datetime (model.date |> DateTime.formatUtc "yyyy-MM-dd"), class "uppercase text-xs text-gray-500 font-bold" ] [ text (model.date |> DateTime.formatUtc "MMM dd, yyyy") ]
        , h2 [ css [ "mt-1 text-2xl tracking-tight font-extrabold text-gray-900", md [ "text-3xl leading-none" ] ] ]
            [ a [ href model.link ] [ text model.title ] ]
        , div [ class "mt-6" ]
            [ p [] [ text model.excerpt ] ]
        , div [ class "mt-10" ]
            [ a [ class "text-indigo-600 uppercase text-sm tracking-wide font-black", href model.link ] [ text "Read full story →" ] ]
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
