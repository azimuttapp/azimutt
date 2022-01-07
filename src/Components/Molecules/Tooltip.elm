module Components.Molecules.Tooltip exposing (b, bl, br, doc, l, lt, r, t, tr)

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


t : String -> Html msg -> Html msg
t =
    tooltip [ Tw.bottom_full, Tw.mb_3, Tw.items_center ] [ Tw.top_full, Tu.translate_y -50 "%" ]


lt : String -> Html msg -> Html msg
lt =
    tooltip [ Tw.bottom_full, Tw.mb_3, Tw.right_0, Tw.items_end ] [ Tw.top_full, Tu.translate_y -50 "%", Tw.mr_3 ]


tr : String -> Html msg -> Html msg
tr =
    tooltip [ Tw.bottom_full, Tw.mb_3, Tw.left_0 ] [ Tw.top_full, Tu.translate_y -50 "%", Tw.ml_3 ]


l : String -> Html msg -> Html msg
l =
    tooltip [ Tw.right_full, Tw.mr_3, Tu.top 50 "%", Tw.transform, Tu.translate_y -50 "%", Tw.items_end ] [ Tu.top 50 "%", Tu.translate_x_y 50 -50 "%" ]


r : String -> Html msg -> Html msg
r =
    tooltip [ Tw.left_full, Tw.ml_3, Tu.top 50 "%", Tw.transform, Tu.translate_y -50 "%" ] [ Tu.top 50 "%", Tu.translate_x_y -50 -50 "%" ]


b : String -> Html msg -> Html msg
b =
    tooltip [ Tw.top_full, Tw.mt_3, Tw.items_center ] [ Tw.top_0, Tu.translate_y -50 "%" ]


bl : String -> Html msg -> Html msg
bl =
    tooltip [ Tw.top_full, Tw.mt_3, Tw.right_0, Tw.items_end ] [ Tw.top_0, Tu.translate_y -50 "%", Tw.mr_3 ]


br : String -> Html msg -> Html msg
br =
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
                    [ span [] [ Button.primary3 Color.indigo [] [ text "Top" ] |> t "Top aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Top left" ] |> lt "Top left aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Top right" ] |> tr "Top right aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Left" ] |> l "Left aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Right" ] |> r "Right aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Bottom" ] |> b "Bottom aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Bottom left" ] |> bl "Bottom left aligned tooltip with more text." ]
                    , span [ css [ Tw.ml_3 ] ] [ Button.primary3 Color.indigo [] [ text "Bottom right" ] |> br "Bottom right aligned tooltip with more text." ]
                    ]
              )
            , ( "global styles", div [] [ Styles.global, text "Global styles are needed for tooltip reveal" ] )
            ]
