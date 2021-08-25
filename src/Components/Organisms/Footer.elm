module Components.Organisms.Footer exposing (footerChapter, footerSlice)

import Components.Atoms.Icon as Icon
import Css
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, div, p, span, text)
import Html.Styled.Attributes exposing (css, href)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


footerSlice : Html msg
footerSlice =
    div [ css [ Tw.mt_8, Tw.border_t, Tw.border_gray_200, Tw.py_8, Tw.px_8, Bp.md [ Tw.flex, Tw.items_center, Tw.justify_between ] ] ]
        [ div [ css [ Tw.flex, Tw.space_x_6, Bp.md [ Tw.order_2 ] ] ]
            [ a [ href twitterLink, css [ Tw.text_gray_400, Css.hover [ Tw.text_gray_500 ] ] ]
                [ span [ css [ Tw.sr_only ] ] [ text "Twitter" ]
                , Icon.twitter
                ]
            , a [ href githubLink, css [ Tw.text_gray_400, Css.hover [ Tw.text_gray_500 ] ] ]
                [ span [ css [ Tw.sr_only ] ] [ text "GitHub" ]
                , Icon.github
                ]
            ]
        , p [ css [ Tw.mt_8, Tw.text_base, Tw.text_gray_400, Bp.md [ Tw.mt_0, Tw.order_1 ] ] ]
            [ text "© 2021 Azimutt" ]
        ]


twitterLink : String
twitterLink =
    "https://twitter.com/azimuttapp"


githubLink : String
githubLink =
    "https://github.com/azimuttapp/azimuttapp"


footerChapter : Chapter x
footerChapter =
    chapter "Footer"
        |> renderComponentList
            [ ( "default", footerSlice )
            ]
