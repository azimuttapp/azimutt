module Components.Atoms.Button exposing (doc, primary1, primary2, primary3, primary4, primary5, secondary1, secondary2, secondary3, secondary4, secondary5, white1, white2, white3, white4, white5)

import Css
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled as Styled exposing (Attribute, Html, div, text)
import Html.Styled.Attributes exposing (css, type_)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Tailwind.Utilities as Tw


primary1 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary1 =
    primary [ Tw.px_2_dot_5, Tw.py_1_dot_5, Tw.text_xs, Tw.rounded ]


primary2 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary2 =
    primary [ Tw.px_3, Tw.py_2, Tw.text_sm, Tw.leading_4, Tw.rounded_md ]


primary3 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary3 =
    primary [ Tw.px_4, Tw.py_2, Tw.text_sm, Tw.rounded_md ]


primary4 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary4 =
    primary [ Tw.px_4, Tw.py_2, Tw.text_base, Tw.rounded_md ]


primary5 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary5 =
    primary [ Tw.px_6, Tw.py_3, Tw.text_base, Tw.rounded_md ]


secondary1 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary1 =
    secondary [ Tw.px_2_dot_5, Tw.py_1_dot_5, Tw.text_xs, Tw.rounded ]


secondary2 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary2 =
    secondary [ Tw.px_3, Tw.py_2, Tw.text_sm, Tw.leading_4, Tw.rounded_md ]


secondary3 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary3 =
    secondary [ Tw.px_4, Tw.py_2, Tw.text_sm, Tw.rounded_md ]


secondary4 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary4 =
    secondary [ Tw.px_4, Tw.py_2, Tw.text_base, Tw.rounded_md ]


secondary5 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary5 =
    secondary [ Tw.px_6, Tw.py_3, Tw.text_base, Tw.rounded_md ]


white1 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white1 =
    white [ Tw.px_2_dot_5, Tw.py_1_dot_5, Tw.text_xs, Tw.rounded ]


white2 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white2 =
    white [ Tw.px_3, Tw.py_2, Tw.text_sm, Tw.leading_4, Tw.rounded_md ]


white3 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white3 =
    white [ Tw.px_4, Tw.py_2, Tw.text_sm, Tw.rounded_md ]


white4 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white4 =
    white [ Tw.px_4, Tw.py_2, Tw.text_base, Tw.rounded_md ]


white5 : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white5 =
    white [ Tw.px_6, Tw.py_3, Tw.text_base, Tw.rounded_md ]


primary : List Css.Style -> TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
primary styles color attrs content =
    Styled.button (attrs ++ [ type_ "button", css (styles ++ commonStyles color ++ [ Tw.border_transparent, Tw.shadow_sm, Tw.text_white, TwColor.render Bg color L600, Css.hover [ TwColor.render Bg color L700 ] ]) ]) content


secondary : List Css.Style -> TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
secondary styles color attrs content =
    Styled.button (attrs ++ [ type_ "button", css (styles ++ commonStyles color ++ [ Tw.border_transparent, TwColor.render Text color L700, TwColor.render Bg color L100, Css.hover [ TwColor.render Bg color L200 ] ]) ]) content


white : List Css.Style -> TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
white styles color attrs content =
    Styled.button (attrs ++ [ type_ "button", css (styles ++ commonStyles color ++ [ Tw.border_gray_300, Tw.shadow_sm, Tw.text_gray_700, Tw.bg_white, Css.hover [ Tw.bg_gray_50 ] ]) ]) content


commonStyles : TwColor -> List Css.Style
commonStyles color =
    [ Tw.inline_flex, Tw.justify_center, Tw.items_center, Tw.border, Tw.font_medium, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, TwColor.render Ring color L500 ] ]



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
