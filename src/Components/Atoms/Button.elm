module Components.Atoms.Button exposing (commonStyles, doc, light, light1, light2, light3, light4, light5, primary, primary1, primary2, primary3, primary4, primary5, secondary, secondary1, secondary2, secondary3, secondary4, secondary5, size1, size2, size3, size4, size5, white, white1, white2, white3, white4, white5)

import Css
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Attribute, Html, button, div, text)
import Html.Styled.Attributes exposing (css, type_)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Libs.Tailwind.Utilities as Tu
import Tailwind.Utilities as Tw


primary1 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary1 =
    build primary size1


primary2 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary2 =
    build primary size2


primary3 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary3 =
    build primary size3


primary4 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary4 =
    build primary size4


primary5 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary5 =
    build primary size5


secondary1 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary1 =
    build secondary size1


secondary2 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary2 =
    build secondary size2


secondary3 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary3 =
    build secondary size3


secondary4 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary4 =
    build secondary size4


secondary5 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary5 =
    build secondary size5


light1 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
light1 =
    build light size1


light2 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
light2 =
    build light size2


light3 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
light3 =
    build light size3


light4 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
light4 =
    build light size4


light5 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
light5 =
    build light size5


white1 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white1 =
    build white size1


white2 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white2 =
    build white size2


white3 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white3 =
    build white size3


white4 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white4 =
    build white size4


white5 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white5 =
    build white size5


primary : TwColor -> List Css.Style
primary color =
    [ Tw.border_transparent, Tw.shadow_sm, Tw.text_white, TwColor.render Bg color L600, Css.hover [ TwColor.render Bg color L700 ] ]


secondary : TwColor -> List Css.Style
secondary color =
    [ Tw.border_transparent, TwColor.render Text color L700, TwColor.render Bg color L100, Css.hover [ TwColor.render Bg color L200 ] ]


light : TwColor -> List Css.Style
light color =
    [ Tw.border_transparent, TwColor.render Text color L800, TwColor.render Bg color L50, Css.hover [ TwColor.render Bg color L100 ] ]


white : TwColor -> List Css.Style
white color =
    [ Tw.border_gray_300, Tw.shadow_sm, TwColor.render Text color L700, Tw.bg_white, Css.hover [ TwColor.render Bg color L50 ] ]


size1 : List Css.Style
size1 =
    [ Tw.px_2_dot_5, Tw.py_1_dot_5, Tw.text_xs, Tw.rounded ]


size2 : List Css.Style
size2 =
    [ Tw.px_3, Tw.py_2, Tw.text_sm, Tw.leading_4, Tw.rounded_md ]


size3 : List Css.Style
size3 =
    [ Tw.px_4, Tw.py_2, Tw.text_sm, Tw.rounded_md ]


size4 : List Css.Style
size4 =
    [ Tw.px_4, Tw.py_2, Tw.text_base, Tw.rounded_md ]


size5 : List Css.Style
size5 =
    [ Tw.px_6, Tw.py_3, Tw.text_base, Tw.rounded_md ]


commonStyles : TwColor -> List Css.Style
commonStyles color =
    [ Tw.inline_flex, Tw.justify_center, Tw.items_center, Tw.border, Tw.font_medium, Tu.focusRing ( color, L500 ) ( White, L500 ) ]


build : (TwColor -> List Css.Style) -> List Css.Style -> TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
build colorStyles sizeStyles color attrs content =
    button (attrs ++ [ type_ "button", css (commonStyles color ++ colorStyles color ++ sizeStyles) ]) content



-- DOCUMENTATION


doc : Theme -> Chapter x
doc theme =
    chapter "Button"
        |> renderComponentList
            [ ( "primary"
              , div []
                    [ primary1 theme.color [ css [ Tw.mr_3 ] ] [ text "primary1" ]
                    , primary2 theme.color [ css [ Tw.mr_3 ] ] [ text "primary2" ]
                    , primary3 theme.color [ css [ Tw.mr_3 ] ] [ text "primary3" ]
                    , primary4 theme.color [ css [ Tw.mr_3 ] ] [ text "primary4" ]
                    , primary5 theme.color [ css [ Tw.mr_3 ] ] [ text "primary5" ]
                    ]
              )
            , ( "secondary"
              , div []
                    [ secondary1 theme.color [ css [ Tw.mr_3 ] ] [ text "secondary1" ]
                    , secondary2 theme.color [ css [ Tw.mr_3 ] ] [ text "secondary2" ]
                    , secondary3 theme.color [ css [ Tw.mr_3 ] ] [ text "secondary3" ]
                    , secondary4 theme.color [ css [ Tw.mr_3 ] ] [ text "secondary4" ]
                    , secondary5 theme.color [ css [ Tw.mr_3 ] ] [ text "secondary5" ]
                    ]
              )
            , ( "light"
              , div []
                    [ light1 theme.color [ css [ Tw.mr_3 ] ] [ text "light1" ]
                    , light2 theme.color [ css [ Tw.mr_3 ] ] [ text "light2" ]
                    , light3 theme.color [ css [ Tw.mr_3 ] ] [ text "light3" ]
                    , light4 theme.color [ css [ Tw.mr_3 ] ] [ text "light4" ]
                    , light5 theme.color [ css [ Tw.mr_3 ] ] [ text "light5" ]
                    ]
              )
            , ( "white"
              , div []
                    [ white1 theme.color [ css [ Tw.mr_3 ] ] [ text "white1" ]
                    , white2 theme.color [ css [ Tw.mr_3 ] ] [ text "white2" ]
                    , white3 theme.color [ css [ Tw.mr_3 ] ] [ text "white3" ]
                    , white4 theme.color [ css [ Tw.mr_3 ] ] [ text "white4" ]
                    , white5 theme.color [ css [ Tw.mr_3 ] ] [ text "white5" ]
                    ]
              )
            ]
