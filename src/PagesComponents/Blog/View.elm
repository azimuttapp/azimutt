module PagesComponents.Blog.View exposing (viewBlog)

import Components.Slices.Blog as Blog
import Components.Slices.Newsletter as Newsletter
import Conf
import Html exposing (Html, div, h1, hr, p, text)
import Html.Attributes exposing (style)
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css)
import Libs.Tailwind exposing (hover)
import PagesComponents.Blog.Models exposing (Model)
import PagesComponents.Helpers as Helpers


viewBlog : Model -> List (Html msg)
viewBlog model =
    [ Helpers.publicHeader
    , div [ css [ "mt-24 max-w-prose mx-auto text-center" ] ]
        [ h1 [ css [ "text-4xl font-black" ] ]
            [ text "Azimutt blog" ]
        , p [ css [ "text-lg mt-6" ] ]
            [ text "Hi! We are "
            , extLink "https://twitter.com/sbouaked" [ css [ "text-indigo-600", hover [ "underline" ] ] ] [ text "Samir" ]
            , text " and "
            , extLink "https://twitter.com/loicknuchel" [ css [ "text-indigo-600", hover [ "underline" ] ] ] [ text "Loïc" ]
            , text ". We're building an application to empower developers understanding their relational databases. You can read about how we build it and how to use it on this blog."
            ]
        ]
    , div [ css [ "mt-12" ] ] [ Newsletter.centered Conf.newsletter ]
    , hr [ css [ "w-full bg-gray-100 my-12" ], style "height" "1px" ] []
    , div [ css [ "mt-16 mb-24 max-w-prose mx-auto" ] ] (model.articles |> List.map Tuple.second |> List.map Blog.article |> List.intersperse (hr [ css [ "w-full bg-gray-100 my-12" ], style "height" "1px" ] []))

    -- add it when out of initial page, Helpers.newsletterSection
    , Helpers.publicFooter
    ]
