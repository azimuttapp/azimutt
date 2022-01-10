module Components.Atoms.Dots exposing (doc, dots, dotsBottomRight, dotsMiddleLeft, dotsTopRight)

import Css
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div)
import Html.Styled.Attributes as HtmlAttr
import Libs.Tailwind.Utilities as Tu
import Svg.Styled exposing (defs, pattern, rect, svg)
import Svg.Styled.Attributes exposing (css, fill, height, id, patternUnits, viewBox, width, x, y)
import Tailwind.Utilities as Tw


dotsTopRight : String -> Int -> Html msg
dotsTopRight id height =
    dots id 404 height [ Tw.top_12, Tw.left_full, Tw.translate_x_32 ]


dotsMiddleLeft : String -> Int -> Html msg
dotsMiddleLeft id height =
    dots id 404 height [ Tw.top_1over2, Tw.right_full, Tw.neg_translate_y_1over2, Tw.neg_translate_x_32 ]


dotsBottomRight : String -> Int -> Html msg
dotsBottomRight id height =
    dots id 404 height [ Tw.bottom_12, Tw.left_full, Tw.translate_x_32 ]


dots : String -> Int -> Int -> List Css.Style -> Html msg
dots patternId dotsWidth dotsHeight styles =
    svg
        [ width (String.fromInt dotsWidth)
        , height (String.fromInt dotsHeight)
        , viewBox ("0 0 " ++ String.fromInt dotsWidth ++ " " ++ String.fromInt dotsHeight)
        , fill "none"
        , css ([ Tw.absolute, Tw.transform ] ++ styles)
        ]
        [ defs []
            [ pattern [ id patternId, x "0", y "0", width "20", height "20", patternUnits "userSpaceOnUse" ]
                [ rect [ x "0", y "0", width "4", height "4", fill "currentColor", css [ Tw.text_gray_200 ] ] []
                ]
            ]
        , rect [ width (String.fromInt dotsWidth), height (String.fromInt dotsHeight), fill ("url(#" ++ patternId ++ ")") ] []
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Dots"
        |> renderComponentList
            [ ( "dots", div [ HtmlAttr.css [ Tu.h 384 "px" ] ] [ dots "id" 404 384 [] ] )
            ]
