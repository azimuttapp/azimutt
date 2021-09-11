module Components.Slices.Cta exposing (doc, slice)

import Conf exposing (constants)
import Css exposing (hover)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Gen.Route as Route
import Html.Styled exposing (Html, a, div, h2, span, text)
import Html.Styled.Attributes exposing (css, href, rel, target)
import Tailwind.Breakpoints exposing (lg, sm)
import Tailwind.Utilities exposing (bg_gradient_to_r, bg_indigo_100, bg_indigo_50, bg_white, block, border, border_transparent, flex, flex_shrink_0, font_extrabold, font_medium, from_purple_600, from_purple_700, h_14, items_center, justify_between, justify_center, max_w_4xl, max_w_7xl, ml_3, mt_0, mt_8, mx_auto, px_4, px_5, px_6, px_8, py_16, py_24, py_3, rounded_md, shadow_sm, text_4xl, text_base, text_gray_900, text_indigo_800, text_white, to_indigo_600, to_indigo_700, tracking_tight)


slice : Html msg
slice =
    div [ css [ bg_white ] ]
        [ div [ css [ max_w_4xl, mx_auto, py_16, px_4, lg [ max_w_7xl, px_8, flex, items_center, justify_between ], sm [ px_6, py_24 ] ] ]
            [ h2 [ css [ text_4xl, font_extrabold, tracking_tight, text_gray_900 ] ]
                [ span [ css [ block ] ] [ text "Ready to explore your SQL schema?" ]
                ]
            , div [ css [ mt_8, flex, lg [ mt_0, flex_shrink_0 ] ] ]
                [ a [ href (Route.toHref Route.App), css [ flex, items_center, justify_center, px_5, py_3, h_14, border, border_transparent, text_base, font_medium, rounded_md, shadow_sm, text_white, bg_gradient_to_r, from_purple_600, to_indigo_600, hover [ text_white, from_purple_700, to_indigo_700 ] ] ]
                    [ text "Explore now!" ]
                , a [ href constants.azimuttGithub, target "_blank", rel "noopener", css [ flex, ml_3, items_center, justify_center, px_5, py_3, h_14, border, border_transparent, text_base, font_medium, rounded_md, shadow_sm, text_indigo_800, bg_indigo_50, hover [ text_indigo_800, bg_indigo_100 ] ] ]
                    [ text "Learn more" ]
                ]
            ]
        ]


doc : Chapter x
doc =
    chapter "Cta"
        |> renderComponentList
            [ ( "slice", slice )
            ]
