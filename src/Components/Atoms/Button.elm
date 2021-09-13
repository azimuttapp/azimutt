module Components.Atoms.Button exposing (ButtonProps, button, doc)

import Css exposing (focus, hover)
import ElmBook exposing (Msg)
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled as Styled exposing (Html, text)
import Html.Styled.Attributes exposing (css, disabled, type_)
import Html.Styled.Events exposing (onClick)
import Tailwind.Utilities exposing (bg_indigo_600, bg_indigo_700, border, border_transparent, font_medium, inline_flex, items_center, justify_center, outline_none, px_5, py_3, ring_2, ring_indigo_500, ring_offset_2, rounded_md, text_base, text_white)


type alias ButtonProps msg =
    { label : String, disabled : Bool, onClick : msg }


button : ButtonProps msg -> Html msg
button props =
    Styled.button
        [ type_ "button"
        , disabled props.disabled
        , onClick props.onClick
        , css [ inline_flex, items_center, justify_center, px_5, py_3, border, border_transparent, text_base, font_medium, rounded_md, text_white, bg_indigo_600, focus [ outline_none, ring_2, ring_offset_2, ring_indigo_500 ], hover [ bg_indigo_700 ] ]
        ]
        [ text props.label ]


doc : Chapter x
doc =
    let
        defaultProps : ButtonProps (Msg state)
        defaultProps =
            { label = "Click me!", disabled = False, onClick = logAction "Clicked button" }
    in
    chapter "Button"
        |> renderComponentList
            [ ( "default", button { defaultProps | onClick = logAction "Clicked default button" } )
            , ( "disabled", button { defaultProps | disabled = True } )
            ]
