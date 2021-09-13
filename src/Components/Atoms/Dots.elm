module Components.Atoms.Dots exposing (doc, dots)

import Css exposing (Style, property)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div)
import Html.Styled.Attributes as HtmlAttr
import Svg.Styled exposing (defs, pattern, rect, svg)
import Svg.Styled.Attributes exposing (css, fill, height, id, patternUnits, viewBox, width, x, y)
import Tailwind.Utilities exposing (absolute, text_gray_200, transform)


dots : String -> List Style -> Html msg
dots patternId style =
    svg [ width "404", height "784", viewBox "0 0 404 784", fill "none", css ([ absolute, transform ] ++ style) ]
        [ defs []
            [ pattern [ id patternId, x "0", y "0", width "20", height "20", patternUnits "userSpaceOnUse" ]
                [ rect [ x "0", y "0", width "4", height "4", fill "currentColor", css [ text_gray_200 ] ] []
                ]
            ]
        , rect [ width "404", height "784", fill ("url(#" ++ patternId ++ ")") ] []
        ]


doc : Chapter x
doc =
    chapter "Dots"
        |> renderComponentList
            [ ( "dots", div [ HtmlAttr.css [ property "height" "784px" ] ] [ dots "id" [] ] )
            ]
