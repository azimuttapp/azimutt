module Components.Molecules.Tooltip exposing (bottom, bottomLeft, bottomRight, doc, left, right, top, topLeft, topRight)

import Components.Atoms.Button as Button
import Components.Atoms.Styles as Styles
import Css
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div, span, text)
import Html.Styled.Attributes exposing (class, css)
import Libs.Models.Color as Color
import Libs.Tailwind.Utilities as Tu
import Tailwind.Utilities as Tw



-- see https://elmcsspatterns.io/feedback/tooltip
-- see https://codepen.io/robstinson/pen/eYZLRdv
-- see https://tailwindcomponents.com/component/tooltip


top : String -> Html msg -> Html msg
top =
    tooltip [ Tw.bottom_full, Tw.mb_3, Tw.items_center ] [ Tw.top_full, Tu.translate_y -50 "%" ]


topLeft : String -> Html msg -> Html msg
topLeft =
    tooltip [ Tw.bottom_full, Tw.mb_3, Tw.right_0, Tw.items_end ] [ Tw.top_full, Tu.translate_y -50 "%", Tw.mr_3 ]


topRight : String -> Html msg -> Html msg
topRight =
    tooltip [ Tw.bottom_full, Tw.mb_3, Tw.left_0 ] [ Tw.top_full, Tu.translate_y -50 "%", Tw.ml_3 ]


left : String -> Html msg -> Html msg
left =
    tooltip [ Tw.right_full, Tw.mr_3, Tu.top 50 "%", Tw.transform, Tu.translate_y -50 "%", Tw.items_end ] [ Tu.top 50 "%", Tu.translate_x_y 50 -50 "%" ]


right : String -> Html msg -> Html msg
right =
    tooltip [ Tw.left_full, Tw.ml_3, Tu.top 50 "%", Tw.transform, Tu.translate_y -50 "%" ] [ Tu.top 50 "%", Tu.translate_x_y -50 -50 "%" ]


bottom : String -> Html msg -> Html msg
bottom =
    tooltip [ Tw.top_full, Tw.mt_3, Tw.items_center ] [ Tw.top_0, Tu.translate_y -50 "%" ]


bottomLeft : String -> Html msg -> Html msg
bottomLeft =
    tooltip [ Tw.top_full, Tw.mt_3, Tw.right_0, Tw.items_end ] [ Tw.top_0, Tu.translate_y -50 "%", Tw.mr_3 ]


bottomRight : String -> Html msg -> Html msg
bottomRight =
    tooltip [ Tw.top_full, Tw.mt_3, Tw.left_0 ] [ Tw.top_0, Tu.translate_y -50 "%", Tw.ml_3 ]


tooltip : List Css.Style -> List Css.Style -> String -> Html msg -> Html msg
tooltip bubble caret value content =
    div [ class "group", css [ Tw.relative, Tw.inline_flex, Tw.flex_col, Tw.items_center ] ]
        [ content
        , div [ class "group-hover-flex", css ([ Tw.hidden, Tw.absolute, Tw.flex_col, Tu.z_max ] ++ bubble) ]
            [ div [ css ([ Tw.absolute, Tw.w_3, Tw.h_3, Tw.bg_black, Tw.transform, Tw.rotate_45 ] ++ caret) ] []
            , span [ css [ Tw.relative, Tw.p_2, Tw.bg_black, Tw.text_white, Tw.text_xs, Tw.leading_none, Tw.whitespace_nowrap, Tw.rounded, Tw.shadow_lg ] ] [ text value ]
            ]
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Tooltip"
        |> Chapter.renderComponentList
            [ ( "tooltip"
              , div []
                    [ span [] [ Button.primary3 Color.indigo [] [ text "Top" ] |> top "Top aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Top left" ] |> topLeft "Top left aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Top right" ] |> topRight "Top right aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Left" ] |> left "Left aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Right" ] |> right "Right aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Bottom" ] |> bottom "Bottom aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Bottom left" ] |> bottomLeft "Bottom left aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Bottom right" ] |> bottomRight "Bottom right aligned tooltip with more text." ]
                    ]
              )
            , ( "global styles", div [] [ Styles.global, text "Global styles are needed for tooltip reveal" ] )
            ]
