module Components.Slices.Cta exposing (doc, slice)

import Conf
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Gen.Route as Route
import Html exposing (Html, a, div, h2, span, text)
import Html.Attributes exposing (href)
import Html.Styled exposing (fromUnstyled)
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css, track)
import Libs.Tailwind exposing (hover, lg, sm)
import Track


slice : Html msg
slice =
    div [ css [ "bg-white" ] ]
        [ div [ css [ "max-w-4xl mx-auto py-16 px-4", lg "max-w-7xl px-8 flex items-center justify-between", sm "px-6 py-24" ] ]
            [ h2 [ css [ "text-4xl font-extrabold tracking-tight text-gray-900" ] ]
                [ span [ css [ "block" ] ] [ text "Ready to explore your SQL schema?" ]
                ]
            , div [ css [ "mt-8 flex", lg "mt-0 flex-shrink-0" ] ]
                [ a ([ href (Route.toHref Route.App), css [ "flex items-center justify-center px-5 py-3 h-14 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-gradient-to-r from-green-600 to-indigo-600", hover "text-white from-green-700 to-indigo-700" ] ] ++ track (Track.openAppCta "home-cta"))
                    [ text "Explore now!" ]
                , extLink Conf.constants.azimuttGithub
                    [ css [ "flex ml-3 items-center justify-center px-5 py-3 h-14 border border-transparent text-base font-medium rounded-md shadow-sm text-indigo-800 bg-indigo-50", hover "text-indigo-800 bg-indigo-100" ] ]
                    [ text "Learn more" ]
                ]
            ]
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Cta"
        |> renderComponentList
            [ ( "slice", slice |> fromUnstyled )
            ]
