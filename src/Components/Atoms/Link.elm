module Components.Atoms.Link exposing (doc, light1, light2, light3, light4, light5, primary1, primary2, primary3, primary4, primary5, secondary1, secondary2, secondary3, secondary4, secondary5, white1, white2, white3, white4, white5)

import Components.Atoms.Button exposing (commonStyles, light, primary, secondary, size1, size2, size3, size4, size5, white)
import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html exposing (Attribute, Html, a, div, text)
import Html.Attributes exposing (href)
import Libs.Html.Attributes exposing (css)
import Libs.Tailwind as Tw exposing (Color, TwClass)


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


build : (Color -> TwClass) -> TwClass -> Color -> List (Attribute msg) -> List (Html msg) -> Html msg
build colorStyles sizeStyles color attrs content =
    a (attrs ++ [ css [ commonStyles color, colorStyles color, sizeStyles ] ]) content



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Link"
        |> renderComponentList
            [ ( "primary"
              , div []
                    [ primary1 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "primary1" ]
                    , primary2 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "primary2" ]
                    , primary3 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "primary3" ]
                    , primary4 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "primary4" ]
                    , primary5 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "primary5" ]
                    ]
              )
            , ( "secondary"
              , div []
                    [ secondary1 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "secondary1" ]
                    , secondary2 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "secondary2" ]
                    , secondary3 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "secondary3" ]
                    , secondary4 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "secondary4" ]
                    , secondary5 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "secondary5" ]
                    ]
              )
            , ( "light"
              , div []
                    [ light1 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "light1" ]
                    , light2 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "light2" ]
                    , light3 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "light3" ]
                    , light4 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "light4" ]
                    , light5 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "light5" ]
                    ]
              )
            , ( "white"
              , div []
                    [ white1 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "white1" ]
                    , white2 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "white2" ]
                    , white3 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "white3" ]
                    , white4 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "white4" ]
                    , white5 Tw.primary [ href "#", css [ "mr-3" ] ] [ text "white5" ]
                    ]
              )
            ]
