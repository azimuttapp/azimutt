module Components.Slices.NotFound exposing (Brand, SimpleModel, doc, simple)

import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, a, div, footer, h1, img, main_, nav, p, span, text)
import Html.Attributes exposing (alt, class, href, src)
import Libs.Html.Attributes exposing (ariaHidden, css)
import Libs.Models exposing (Image, Link)
import Libs.Tailwind exposing (hover, lg, sm)


type alias SimpleModel =
    { brand : Brand
    , header : String
    , title : String
    , message : String
    , links : List Link
    , footer : List Link
    }


type alias Brand =
    { img : Image, link : Link }


simple : SimpleModel -> Html msg
simple model =
    div [ class "min-h-full pt-16 pb-12 flex flex-col bg-white" ]
        [ main_ [ css [ "flex-grow flex flex-col justify-center max-w-7xl w-full mx-auto px-4", sm [ "px-6" ], lg [ "px-8" ] ] ]
            [ div [ class "flex-shrink-0 flex justify-center" ]
                [ a [ href model.brand.link.url, class "inline-flex" ]
                    [ span [ class "sr-only" ] [ text model.brand.link.text ]
                    , img [ class "h-12 w-auto", src model.brand.img.src, alt model.brand.img.alt ] []
                    ]
                ]
            , div [ class "py-16" ]
                [ div [ class "text-center" ]
                    [ p [ class "text-sm font-semibold text-primary-600 uppercase tracking-wide" ] [ text model.header ]
                    , h1 [ css [ "mt-2 text-4xl font-extrabold text-gray-900 tracking-tight", sm [ "text-5xl" ] ] ] [ text model.title ]
                    , p [ class "mt-2 text-base text-gray-500" ] [ text model.message ]
                    , div [ class "mt-6 flex justify-center space-x-4" ]
                        (model.links
                            |> List.map (\link -> a [ href link.url, css [ "text-base font-medium text-primary-600", hover [ "text-primary-500" ] ] ] [ text link.text ])
                            |> List.intersperse (span [ class "inline-block border-l border-gray-300", ariaHidden True ] [])
                        )
                    ]
                ]
            ]
        , footer [ css [ "flex-shrink-0 max-w-7xl w-full mx-auto px-4 ", sm [ "px-6" ], lg [ "px-8" ] ] ]
            [ nav [ class "flex justify-center space-x-4" ]
                (model.footer
                    |> List.map (\link -> a [ href link.url, css [ "text-sm font-medium text-gray-500 ", hover [ "text-gray-600" ] ] ] [ text link.text ])
                    |> List.intersperse (span [ class "inline-block border-l border-gray-300", ariaHidden True ] [])
                )
            ]
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "NotFound"
        |> Chapter.renderComponentList
            [ ( "simple", simple docModel )
            ]


docModel : SimpleModel
docModel =
    { brand =
        { img = { src = "https://tailwindui.com/img/logos/workflow-mark.svg?color=indigo&shade=600", alt = "Workflow" }
        , link = { url = "#", text = "Workflow" }
        }
    , header = "404 error"
    , title = "Page not found."
    , message = "Sorry, we couldn't find the page you’re looking for."
    , links = [ { url = "#", text = "Go back home" } ]
    , footer = [ { url = "#", text = "Contact Support" }, { url = "#", text = "Status" }, { url = "#", text = "Twitter" } ]
    }
