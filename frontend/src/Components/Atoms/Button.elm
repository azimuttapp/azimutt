module Components.Atoms.Button exposing (commonStyles, doc, light, light1, light2, light3, light4, light5, primary, primary1, primary2, primary3, primary4, primary5, secondary, secondary1, secondary2, secondary3, secondary4, secondary5, size1, size2, size3, size4, size5, white, white1, white2, white3, white4, white5)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html exposing (Attribute, Html, button, div, text)
import Html.Attributes exposing (disabled, type_)
import Libs.Html.Attributes exposing (css)
import Libs.Tailwind as Tw exposing (Color, TwClass, batch, bg_100, bg_200, bg_300, bg_50, bg_600, bg_700, focus_ring_500, hover, text_300, text_700, text_800)


primary1 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
primary1 =
    build primary size1


primary2 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
primary2 =
    build primary size2


primary3 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
primary3 =
    build primary size3


primary4 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
primary4 =
    build primary size4


primary5 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
primary5 =
    build primary size5


secondary1 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary1 =
    build secondary size1


secondary2 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary2 =
    build secondary size2


secondary3 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary3 =
    build secondary size3


secondary4 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary4 =
    build secondary size4


secondary5 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary5 =
    build secondary size5


light1 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
light1 =
    build light size1


light2 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
light2 =
    build light size2


light3 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
light3 =
    build light size3


light4 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
light4 =
    build light size4


light5 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
light5 =
    build light size5


white1 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
white1 =
    build white size1


white2 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
white2 =
    build white size2


white3 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
white3 =
    build white size3


white4 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
white4 =
    build white size4


white5 : Color -> List (Attribute msg) -> List (Html msg) -> Html msg
white5 =
    build white size5


primary : Color -> TwClass
primary color =
    batch [ "border-transparent shadow-sm text-white", bg_600 color, hover [ bg_700 color ], Tw.disabled [ "cursor-not-allowed", bg_300 color ] ]


secondary : Color -> TwClass
secondary color =
    batch [ "border-transparent", text_700 color, bg_100 color, hover [ bg_200 color ], Tw.disabled [ "cursor-not-allowed", bg_100 color, text_300 color ] ]


light : Color -> TwClass
light color =
    batch [ "border-transparent", text_800 color, bg_50 color, hover [ bg_100 color ], Tw.disabled [ "cursor-not-allowed", bg_50 color, text_300 color ] ]


white : Color -> TwClass
white color =
    batch [ "border-gray-300 shadow-sm bg-white", text_700 color, hover [ bg_50 color ], Tw.disabled [ "cursor-not-allowed border-gray-200 bg-white", text_300 color ] ]


size1 : TwClass
size1 =
    "px-2.5 py-1.5 text-xs rounded"


size2 : TwClass
size2 =
    "px-3 py-2 text-sm leading-4 rounded-md"


size3 : TwClass
size3 =
    "px-4 py-2 text-sm rounded-md"


size4 : TwClass
size4 =
    "px-4 py-2 text-base rounded-md"


size5 : TwClass
size5 =
    "px-6 py-3 text-base rounded-md"


commonStyles : Color -> TwClass
commonStyles color =
    batch [ "inline-flex justify-center items-center border font-medium", focus_ring_500 color ]


build : (Color -> TwClass) -> TwClass -> Color -> List (Attribute msg) -> List (Html msg) -> Html msg
build colorStyles sizeStyles color attrs content =
    button (attrs ++ [ type_ "button", css [ commonStyles color, colorStyles color, sizeStyles ] ]) content



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Button"
        |> renderComponentList
            [ ( "primary"
              , div []
                    [ primary1 Tw.primary [ css [ "mr-3" ] ] [ text "primary1" ]
                    , primary2 Tw.primary [ css [ "mr-3" ] ] [ text "primary2" ]
                    , primary3 Tw.primary [ css [ "mr-3" ] ] [ text "primary3" ]
                    , primary4 Tw.primary [ css [ "mr-3" ] ] [ text "primary4" ]
                    , primary5 Tw.primary [ css [ "mr-3" ] ] [ text "primary5" ]
                    , primary5 Tw.primary [ css [ "mr-3" ], disabled True ] [ text "disabled" ]
                    ]
              )
            , ( "secondary"
              , div []
                    [ secondary1 Tw.primary [ css [ "mr-3" ] ] [ text "secondary1" ]
                    , secondary2 Tw.primary [ css [ "mr-3" ] ] [ text "secondary2" ]
                    , secondary3 Tw.primary [ css [ "mr-3" ] ] [ text "secondary3" ]
                    , secondary4 Tw.primary [ css [ "mr-3" ] ] [ text "secondary4" ]
                    , secondary5 Tw.primary [ css [ "mr-3" ] ] [ text "secondary5" ]
                    , secondary5 Tw.primary [ css [ "mr-3" ], disabled True ] [ text "disabled" ]
                    ]
              )
            , ( "light"
              , div []
                    [ light1 Tw.primary [ css [ "mr-3" ] ] [ text "light1" ]
                    , light2 Tw.primary [ css [ "mr-3" ] ] [ text "light2" ]
                    , light3 Tw.primary [ css [ "mr-3" ] ] [ text "light3" ]
                    , light4 Tw.primary [ css [ "mr-3" ] ] [ text "light4" ]
                    , light5 Tw.primary [ css [ "mr-3" ] ] [ text "light5" ]
                    , light5 Tw.primary [ css [ "mr-3" ], disabled True ] [ text "disabled" ]
                    ]
              )
            , ( "white"
              , div []
                    [ white1 Tw.primary [ css [ "mr-3" ] ] [ text "white1" ]
                    , white2 Tw.primary [ css [ "mr-3" ] ] [ text "white2" ]
                    , white3 Tw.primary [ css [ "mr-3" ] ] [ text "white3" ]
                    , white4 Tw.primary [ css [ "mr-3" ] ] [ text "white4" ]
                    , white5 Tw.primary [ css [ "mr-3" ] ] [ text "white5" ]
                    , white5 Tw.primary [ css [ "mr-3" ], disabled True ] [ text "disabled" ]
                    ]
              )
            ]
