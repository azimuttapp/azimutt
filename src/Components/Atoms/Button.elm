module Components.Atoms.Button exposing (ButtonProps, button, buttonChapter)

import Css
import ElmBook exposing (Msg)
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled as Styled exposing (Html, text)
import Html.Styled.Attributes exposing (css, disabled, type_)
import Html.Styled.Events exposing (onClick)
import Tailwind.Utilities as Tw


type alias ButtonProps msg =
    { label : String, disabled : Bool, onClick : msg }


button : ButtonProps msg -> Html msg
button props =
    Styled.button
        [ type_ "button"
        , disabled props.disabled
        , onClick props.onClick
        , css [ Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.px_5, Tw.py_3, Tw.border, Tw.border_transparent, Tw.text_base, Tw.font_medium, Tw.rounded_md, Tw.text_white, Tw.bg_indigo_600, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, Tw.ring_indigo_500 ], Css.hover [ Tw.bg_indigo_700 ] ]
        ]
        [ text props.label ]


buttonChapter : Chapter x
buttonChapter =
    let
        defaultProps : ButtonProps (Msg state)
        defaultProps =
            { label = "Click me!", disabled = False, onClick = logAction "Clicked button" }
    in
    chapter "Buttons"
        |> renderComponentList
            [ ( "default", button { defaultProps | onClick = logAction "Clicked default button" } )
            , ( "disabled", button { defaultProps | disabled = True } )
            ]
