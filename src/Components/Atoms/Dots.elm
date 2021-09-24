module Components.Atoms.Dots exposing (doc, dots, dotsBottomRight, dotsMiddleLeft, dotsTopRight)

import Css exposing (Style, property)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div)
import Html.Styled.Attributes as HtmlAttr
import Svg.Styled exposing (defs, pattern, rect, svg)
import Svg.Styled.Attributes exposing (css, fill, height, id, patternUnits, viewBox, width, x, y)
import Tailwind.Utilities exposing (absolute, bottom_12, left_full, neg_translate_x_32, neg_translate_y_1over2, right_full, text_gray_200, top_12, top_1over2, transform, translate_x_32)


dotsTopRight : String -> Int -> Html msg
dotsTopRight id height =
    dots id 404 height [ top_12, left_full, translate_x_32 ]


dotsMiddleLeft : String -> Int -> Html msg
dotsMiddleLeft id height =
    dots id 404 height [ top_1over2, right_full, neg_translate_y_1over2, neg_translate_x_32 ]


dotsBottomRight : String -> Int -> Html msg
dotsBottomRight id height =
    dots id 404 height [ bottom_12, left_full, translate_x_32 ]


dots : String -> Int -> Int -> List Style -> Html msg
dots patternId dotsWidth dotsHeight styles =
    svg
        [ width (String.fromInt dotsWidth)
        , height (String.fromInt dotsHeight)
        , viewBox ("0 0 " ++ String.fromInt dotsWidth ++ " " ++ String.fromInt dotsHeight)
        , fill "none"
        , css ([ absolute, transform ] ++ styles)
        ]
        [ defs []
            [ pattern [ id patternId, x "0", y "0", width "20", height "20", patternUnits "userSpaceOnUse" ]
                [ rect [ x "0", y "0", width "4", height "4", fill "currentColor", css [ text_gray_200 ] ] []
                ]
            ]
        , rect [ width (String.fromInt dotsWidth), height (String.fromInt dotsHeight), fill ("url(#" ++ patternId ++ ")") ] []
        ]


doc : Chapter x
doc =
    chapter "Dots"
        |> renderComponentList
            [ ( "dots", div [ HtmlAttr.css [ property "height" "384px" ] ] [ dots "id" 404 384 [] ] )
            ]
