module Components.Slices.Cta exposing (ctaChapter, ctaSlice)

import Css
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Gen.Route as Route
import Html.Styled exposing (Html, a, div, h2, span, text)
import Html.Styled.Attributes exposing (css, href)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


ctaSlice : Html msg
ctaSlice =
    div [ css [ Tw.bg_white ] ]
        [ div [ css [ Tw.max_w_4xl, Tw.mx_auto, Tw.py_16, Tw.px_4, Bp.lg [ Tw.max_w_7xl, Tw.px_8, Tw.flex, Tw.items_center, Tw.justify_between ], Bp.sm [ Tw.px_6, Tw.py_24 ] ] ]
            [ h2 [ css [ Tw.text_4xl, Tw.font_extrabold, Tw.tracking_tight, Tw.text_gray_900 ] ]
                [ span [ css [ Tw.block ] ] [ text "Ready to explore your SQL schema?" ]
                ]
            , div [ css [ Tw.mt_8, Tw.flex, Bp.lg [ Tw.mt_0, Tw.flex_shrink_0 ] ] ]
                [ a [ href (Route.toHref Route.App), css [ Tw.flex, Tw.items_center, Tw.justify_center, Tw.px_5, Tw.py_3, Tw.h_14, Tw.border, Tw.border_transparent, Tw.text_base, Tw.font_medium, Tw.rounded_md, Tw.shadow_sm, Tw.text_white, Tw.text_indigo_800, Tw.bg_indigo_50, Css.hover [ Tw.bg_indigo_100 ] ] ]
                    [ text "Let's start!" ]
                , a [ href documentationLink, css [ Tw.flex, Tw.ml_3, Tw.items_center, Tw.justify_center, Tw.bg_gradient_to_r, Tw.from_purple_600, Tw.to_indigo_600, Tw.px_5, Tw.py_3, Tw.h_14, Tw.border, Tw.border_transparent, Tw.text_base, Tw.font_medium, Tw.rounded_md, Tw.shadow_sm, Tw.text_white, Css.hover [ Tw.from_purple_700, Tw.to_indigo_700, Tw.text_white ] ] ]
                    [ text "Learn more" ]
                ]
            ]
        ]


documentationLink : String
documentationLink =
    "https://github.com/azimuttapp/azimuttapp"


ctaChapter : Chapter x
ctaChapter =
    chapter "Cta"
        |> renderComponentList
            [ ( "default", ctaSlice )
            ]
