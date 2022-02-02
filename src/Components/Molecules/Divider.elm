module Components.Molecules.Divider exposing (doc, withIcon, withLabel, withLabelLeft)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class)
import Html.Styled exposing (fromUnstyled, toUnstyled)
import Libs.Html.Attributes exposing (ariaHidden, css)
import Libs.Tailwind exposing (TwClass)
import Tailwind.Utilities as Tw


withLabel : String -> Html msg
withLabel label =
    divider "justify-center" [ span [ class "px-2 bg-white text-sm text-gray-500" ] [ text label ] ]


withIcon : Icon -> Html msg
withIcon icon =
    divider "justify-center" [ span [ class "bg-white px-2 text-gray-500" ] [ Icon.solid icon [ Tw.text_gray_500 ] |> toUnstyled ] ]


withLabelLeft : String -> Html msg
withLabelLeft label =
    divider "justify-start" [ span [ class "pr-2 bg-white text-sm text-gray-500" ] [ text label ] ]


divider : TwClass -> List (Html msg) -> Html msg
divider position content =
    div [ class "relative" ]
        [ div [ class "absolute inset-0 flex items-center", ariaHidden True ]
            [ div [ class "w-full border-t border-gray-300" ] []
            ]
        , div [ css [ "relative flex", position ] ] content
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Divider"
        |> Chapter.renderComponentList
            [ ( "withLabel", withLabel "Continue" |> fromUnstyled )
            , ( "withIcon", withIcon Plus |> fromUnstyled )
            , ( "withLabelLeft", withLabelLeft "Continue" |> fromUnstyled )
            ]
