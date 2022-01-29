module Components.Molecules.Divider exposing (doc, withIcon, withLabel, withLabelLeft)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Css
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div, span, text)
import Html.Styled.Attributes exposing (css)
import Libs.Html.Styled.Attributes exposing (ariaHidden)
import Tailwind.Utilities as Tw


withLabel : String -> Html msg
withLabel label =
    divider Tw.justify_center [ span [ css [ Tw.px_2, Tw.bg_white, Tw.text_sm, Tw.text_gray_500 ] ] [ text label ] ]


withIcon : Icon -> Html msg
withIcon icon =
    divider Tw.justify_center [ span [ css [ Tw.bg_white, Tw.px_2, Tw.text_gray_500 ] ] [ Icon.solid icon [ Tw.text_gray_500 ] ] ]


withLabelLeft : String -> Html msg
withLabelLeft label =
    divider Tw.justify_start [ span [ css [ Tw.pr_2, Tw.bg_white, Tw.text_sm, Tw.text_gray_500 ] ] [ text label ] ]


divider : Css.Style -> List (Html msg) -> Html msg
divider position content =
    div [ css [ Tw.relative ] ]
        [ div [ css [ Tw.absolute, Tw.inset_0, Tw.flex, Tw.items_center ], ariaHidden True ]
            [ div [ css [ Tw.w_full, Tw.border_t, Tw.border_gray_300 ] ] []
            ]
        , div [ css [ Tw.relative, Tw.flex, position ] ] content
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Divider"
        |> Chapter.renderComponentList
            [ ( "withLabel", withLabel "Continue" )
            , ( "withIcon", withIcon Plus )
            , ( "withLabelLeft", withLabelLeft "Continue" )
            ]
