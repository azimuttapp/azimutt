module Components.Organisms.Footer exposing (doc, slice)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Conf
import Css
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div, p, span, text)
import Html.Styled.Attributes exposing (css)
import Libs.Html.Styled exposing (extLink)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


slice : Html msg
slice =
    div [ css [ Tw.mt_8, Tw.border_t, Tw.border_gray_200, Tw.py_8, Tw.px_8, Bp.md [ Tw.flex, Tw.items_center, Tw.justify_between ] ] ]
        [ div [ css [ Tw.flex, Tw.space_x_6, Bp.md [ Tw.order_2 ] ] ]
            [ extLink Conf.constants.azimuttTwitter
                [ css [ Tw.text_gray_400, Css.hover [ Tw.text_gray_500 ] ] ]
                [ span [ css [ Tw.sr_only ] ] [ text "Twitter" ]
                , Icon.twitter []
                ]
            , extLink Conf.constants.azimuttGithub
                [ css [ Tw.text_gray_400, Css.hover [ Tw.text_gray_500 ] ] ]
                [ span [ css [ Tw.sr_only ] ] [ text "GitHub" ]
                , Icon.github []
                ]
            ]
        , p [ css [ Tw.mt_8, Tw.text_base, Tw.text_gray_400, Bp.md [ Tw.mt_0, Tw.order_1 ] ] ]
            [ text "© 2021 Azimutt" ]
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Footer"
        |> Chapter.renderComponentList
            [ ( "slice", slice )
            ]
