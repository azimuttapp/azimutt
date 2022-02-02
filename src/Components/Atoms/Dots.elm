module Components.Atoms.Dots exposing (doc, dots, dotsBottomRight, dotsMiddleLeft, dotsTopRight)

import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html exposing (Html, div)
import Html.Styled exposing (fromUnstyled)
import Libs.Svg.Attributes exposing (classes)
import Libs.Tailwind exposing (TwClass)
import Svg exposing (defs, pattern, rect, svg)
import Svg.Attributes exposing (fill, height, id, patternUnits, viewBox, width, x, y)


dotsTopRight : String -> Int -> Html msg
dotsTopRight id height =
    dots id 404 height "top-12 left-full translate-x-32"


dotsMiddleLeft : String -> Int -> Html msg
dotsMiddleLeft id height =
    dots id 404 height "top-1/2 right-full -translate-y-1/2 -translate-x-32"


dotsBottomRight : String -> Int -> Html msg
dotsBottomRight id height =
    dots id 404 height "bottom-12 left-full translate-x-32"


dots : String -> Int -> Int -> TwClass -> Html msg
dots patternId dotsWidth dotsHeight styles =
    svg
        [ width (String.fromInt dotsWidth)
        , height (String.fromInt dotsHeight)
        , viewBox ("0 0 " ++ String.fromInt dotsWidth ++ " " ++ String.fromInt dotsHeight)
        , fill "none"
        , classes [ "absolute transform", styles ]
        ]
        [ defs []
            [ pattern [ id patternId, x "0", y "0", width "20", height "20", patternUnits "userSpaceOnUse" ]
                [ rect [ x "0", y "0", width "4", height "4", fill "currentColor", classes [ "text-gray-200" ] ] []
                ]
            ]
        , rect [ width (String.fromInt dotsWidth), height (String.fromInt dotsHeight), fill ("url(#" ++ patternId ++ ")") ] []
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Dots"
        |> renderComponentList
            [ ( "dots", div [ classes [ "h-96" ] ] [ dots "id" 404 384 "" ] |> fromUnstyled )
            ]
