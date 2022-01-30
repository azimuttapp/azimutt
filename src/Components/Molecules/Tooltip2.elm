module Components.Molecules.Tooltip2 exposing (b, bl, br, doc, l, r, t, tl, tr)

import Components.Atoms.Button as Button
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class)
import Html.Styled as Styled
import Html.Styled.Attributes
import Libs.Models.Color as Color
import Libs.Tailwind exposing (TwClass)
import Tailwind.Utilities as Tw



-- see https://elmcsspatterns.io/feedback/tooltip
-- see https://codepen.io/robstinson/pen/eYZLRdv
-- see https://tailwindcomponents.com/component/tooltip


t : String -> Html msg -> Html msg
t =
    tooltip "bottom-full mb-3 items-center" "top-full -translate-y-2/4"


tl : String -> Html msg -> Html msg
tl =
    tooltip "bottom-full mb-3 right-0 items-end" "top-full -translate-y-2/4 mr-3"


tr : String -> Html msg -> Html msg
tr =
    tooltip "bottom-full mb-3 left-0" "top-full -translate-y-2/4 ml-3"


l : String -> Html msg -> Html msg
l =
    tooltip "right-full mr-3 top-1/2 transform -translate-y-2/4 items-end" "top-1/2 translate-x-2/4 -translate-y-2/4"


r : String -> Html msg -> Html msg
r =
    tooltip "left-full ml-3 top-1/2 transform -translate-y-2/4" "top-1/2 -translate-x-2/4 -translate-y-2/4"


b : String -> Html msg -> Html msg
b =
    tooltip "top-full mt-3 items-center" "top-0 -translate-y-2/4"


bl : String -> Html msg -> Html msg
bl =
    tooltip "top-full mt-3 right-0 items-end" "top-0 -translate-y-2/4 mr-3"


br : String -> Html msg -> Html msg
br =
    tooltip "top-full mt-3 left-0" "top-0 -translate-y-2/4 ml-3"


tooltip : TwClass -> TwClass -> String -> Html msg -> Html msg
tooltip bubble caret value content =
    div [ class "group relative inline-flex flex-col items-center" ]
        [ content
        , div [ class ("group-hover:flex hidden absolute flex-col z-max " ++ bubble) ]
            [ div [ class ("absolute w-3 h-3 bg-black transform rotate-45 " ++ caret) ] []
            , span [ class "relative p-2 bg-black text-white text-xs leading-none whitespace-nowrap rounded shadow-lg" ] [ text value ]
            ]
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Tooltip2"
        |> Chapter.renderComponentList
            [ ( "tooltip"
              , Styled.div []
                    ([ ( "Top", t "Top aligned tooltip with more text." )
                     , ( "Top left", tl "Top left aligned tooltip with more text." )
                     , ( "Top right", tr "Top right aligned tooltip with more text." )
                     , ( "Left", l "Left aligned tooltip with more text." )
                     , ( "Right", r "Right aligned tooltip with more text." )
                     , ( "Bottom", b "Bottom aligned tooltip with more text." )
                     , ( "Bottom left", bl "Bottom left aligned tooltip with more text." )
                     , ( "Bottom right", br "Bottom right aligned tooltip with more text." )
                     ]
                        |> List.map
                            (\( value, buildTooltip ) ->
                                Styled.span [ Html.Styled.Attributes.css [ Tw.ml_3 ] ]
                                    [ Button.primary3 Color.indigo [] [ Styled.text value ]
                                        |> Styled.toUnstyled
                                        |> buildTooltip
                                        |> Styled.fromUnstyled
                                    ]
                            )
                    )
              )
            ]
