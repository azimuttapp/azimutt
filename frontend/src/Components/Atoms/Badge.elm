module Components.Atoms.Badge exposing (basic, basicFlex, doc, rounded, roundedFlex)

import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Attribute, Html, span, text)
import Libs.Html.Attributes exposing (css)
import Libs.Tailwind as Tw exposing (Color, bg_100, text_800)


basic : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
basic color attrs content =
    span ([ css [ "px-2 py-0.5 rounded text-xs font-medium", bg_100 color, text_800 color ] ] ++ attrs) content


rounded : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
rounded color attrs content =
    span ([ css [ "px-2.5 py-0.5 rounded-full text-xs font-medium", bg_100 color, text_800 color ] ] ++ attrs) content


basicFlex : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
basicFlex color attrs content =
    span ([ css [ "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium", bg_100 color, text_800 color ] ] ++ attrs) content


roundedFlex : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
roundedFlex color attrs content =
    span ([ css [ "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium", bg_100 color, text_800 color ] ] ++ attrs) content



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Badge"
        |> Chapter.renderComponentList
            [ ( "basic", basic Tw.primary [] [ text "Badge" ] )
            , ( "rounded", rounded Tw.primary [] [ text "Badge" ] )
            , ( "basicFlex", basicFlex Tw.primary [] [ text "Badge" ] )
            , ( "roundedFlex", roundedFlex Tw.primary [] [ text "Badge" ] )
            ]
