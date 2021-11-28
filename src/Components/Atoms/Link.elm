module Components.Atoms.Link exposing (doc, light1, light2, light3, light4, light5, primary1, primary2, primary3, primary4, primary5, secondary1, secondary2, secondary3, secondary4, secondary5, white1, white2, white3, white4, white5)

import Css
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Attribute, Html, a, div, text)
import Html.Styled.Attributes exposing (css)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Libs.Tailwind.Utilities as Tu
import Tailwind.Utilities as Tw


primary1 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary1 =
    primary size1


primary2 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary2 =
    primary size2


primary3 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary3 =
    primary size3


primary4 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary4 =
    primary size4


primary5 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary5 =
    primary size5


secondary1 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary1 =
    secondary size1


secondary2 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary2 =
    secondary size2


secondary3 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary3 =
    secondary size3


secondary4 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary4 =
    secondary size4


secondary5 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary5 =
    secondary size5


light1 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
light1 =
    light size1


light2 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
light2 =
    light size2


light3 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
light3 =
    light size3


light4 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
light4 =
    light size4


light5 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
light5 =
    light size5


white1 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white1 =
    white size1


white2 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white2 =
    white size2


white3 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white3 =
    white size3


white4 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white4 =
    white size4


white5 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white5 =
    white size5


primary : List Css.Style -> TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary styles color attrs content =
    a (attrs ++ [ css (styles ++ commonStyles color ++ [ Tw.border_transparent, Tw.shadow_sm, Tw.text_white, TwColor.render Bg color L600, Css.hover [ TwColor.render Bg color L700 ] ]) ]) content


secondary : List Css.Style -> TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary styles color attrs content =
    a (attrs ++ [ css (styles ++ commonStyles color ++ [ Tw.border_transparent, TwColor.render Text color L700, TwColor.render Bg color L100, Css.hover [ TwColor.render Bg color L200 ] ]) ]) content


light : List Css.Style -> TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
light styles color attrs content =
    a (attrs ++ [ css (styles ++ commonStyles color ++ [ Tw.border_transparent, TwColor.render Text color L800, TwColor.render Bg color L50, Css.hover [ TwColor.render Bg color L100 ] ]) ]) content


white : List Css.Style -> TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white styles color attrs content =
    a (attrs ++ [ css (styles ++ commonStyles color ++ [ Tw.border_gray_300, Tw.shadow_sm, Tw.text_gray_700, Tw.bg_white, Css.hover [ Tw.bg_gray_50 ] ]) ]) content


commonStyles : TwColor -> List Css.Style
commonStyles color =
    [ Tw.inline_flex, Tw.justify_center, Tw.items_center, Tw.border, Tw.font_medium, Tu.focusRing ( color, L500 ) ( White, L500 ) ]


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



-- DOCUMENTATION


doc : Theme -> Chapter x
doc theme =
    chapter "Link"
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
