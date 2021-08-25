module Components.Atoms.Dots exposing (dots, dotsChapter)

import Css exposing (Style)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div)
import Html.Styled.Attributes as HtmlAttr
import Svg.Styled exposing (defs, pattern, rect, svg)
import Svg.Styled.Attributes exposing (css, fill, height, id, patternUnits, viewBox, width, x, y)
import Tailwind.Utilities as Tw


dots : String -> List Style -> Html msg
dots patternId style =
    svg [ width "404", height "784", viewBox "0 0 404 784", fill "none", css ([ Tw.absolute, Tw.transform ] ++ style) ]
        [ defs []
            [ pattern [ id patternId, x "0", y "0", width "20", height "20", patternUnits "userSpaceOnUse" ]
                [ rect [ x "0", y "0", width "4", height "4", fill "currentColor", css [ Tw.text_gray_200 ] ] []
                ]
            ]
        , rect [ width "404", height "784", fill ("url(#" ++ patternId ++ ")") ] []
        ]


dotsChapter : Chapter x
dotsChapter =
    chapter "Dots"
        |> renderComponentList
            [ ( "dots", div [ HtmlAttr.css [ Css.property "height" "784px" ] ] [ dots "id" [] ] )
            ]
