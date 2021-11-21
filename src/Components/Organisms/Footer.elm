module Components.Organisms.Footer exposing (doc, slice)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Conf exposing (constants)
import Css exposing (hover)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div, p, span, text)
import Html.Styled.Attributes exposing (css)
import Libs.Html.Styled exposing (extLink)
import Tailwind.Breakpoints exposing (md)
import Tailwind.Utilities exposing (border_gray_200, border_t, flex, items_center, justify_between, mt_0, mt_8, order_1, order_2, px_8, py_8, space_x_6, sr_only, text_base, text_gray_400, text_gray_500)


slice : Html msg
slice =
    div [ css [ mt_8, border_t, border_gray_200, py_8, px_8, md [ flex, items_center, justify_between ] ] ]
        [ div [ css [ flex, space_x_6, md [ order_2 ] ] ]
            [ extLink constants.azimuttTwitter
                [ css [ text_gray_400, hover [ text_gray_500 ] ] ]
                [ span [ css [ sr_only ] ] [ text "Twitter" ]
                , Icon.twitter []
                ]
            , extLink constants.azimuttGithub
                [ css [ text_gray_400, hover [ text_gray_500 ] ] ]
                [ span [ css [ sr_only ] ] [ text "GitHub" ]
                , Icon.github []
                ]
            ]
        , p [ css [ mt_8, text_base, text_gray_400, md [ mt_0, order_1 ] ] ]
            [ text "© 2021 Azimutt" ]
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Footer"
        |> renderComponentList
            [ ( "slice", slice )
            ]
