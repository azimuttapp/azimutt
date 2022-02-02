module Components.Organisms.Footer exposing (doc, slice)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Conf
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html exposing (Html, div, p, span, text)
import Html.Styled exposing (fromUnstyled, toUnstyled)
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css)
import Libs.Tailwind exposing (hover, md)


slice : Html msg
slice =
    div [ css [ "mt-8 border-t border-gray-200 py-8 px-8", md "flex items-center justify-between" ] ]
        [ div [ css [ "flex space-x-6", md "order-2" ] ]
            [ extLink Conf.constants.azimuttTwitter
                [ css [ "text-gray-400", hover "text-gray-500" ] ]
                [ span [ css [ "sr-only" ] ] [ text "Twitter" ]
                , Icon.twitter [] |> toUnstyled
                ]
            , extLink Conf.constants.azimuttGithub
                [ css [ "text-gray-400", hover "text-gray-500" ] ]
                [ span [ css [ "sr-only" ] ] [ text "GitHub" ]
                , Icon.github [] |> toUnstyled
                ]
            ]
        , p [ css [ "mt-8 text-base text-gray-400", md "mt-0 order-1" ] ]
            [ text "© 2021 Azimutt" ]
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Footer"
        |> Chapter.renderComponentList
            [ ( "slice", slice |> fromUnstyled )
            ]
