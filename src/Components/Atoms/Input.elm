module Components.Atoms.Input exposing (DocState, SharedDocState, checkbox, doc, initDocState, selectWithLabelAndHelp, textWithLabelAndHelp)

import Css
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div, input, label, option, p, select, span, text)
import Html.Styled.Attributes exposing (checked, css, for, id, name, placeholder, selected, type_, value)
import Html.Styled.Events exposing (onClick, onInput)
import Libs.Html.Styled.Attributes exposing (ariaDescribedby)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


textWithLabelAndHelp : List Css.Style -> HtmlId -> String -> String -> String -> String -> String -> (String -> msg) -> Html msg
textWithLabelAndHelp styles fieldId fieldType fieldLabel fieldPlaceholder fieldHelp fieldValue fieldChange =
    div [ css styles ]
        [ label [ for fieldId, css [ Tw.block, Tw.text_sm, Tw.font_medium, Tw.text_gray_700 ] ] [ text fieldLabel ]
        , div [ css [ Tw.mt_1 ] ]
            [ input [ type_ fieldType, name fieldId, id fieldId, value fieldValue, onInput fieldChange, placeholder fieldPlaceholder, ariaDescribedby (fieldId ++ "-help"), css [ Tw.form_input, Tw.shadow_sm, Tw.block, Tw.w_full, Tw.border_gray_300, Tw.rounded_md, Css.focus [ Tw.ring_indigo_500, Tw.border_indigo_500 ], Bp.sm [ Tw.text_sm ] ] ] []
            ]
        , p [ id (fieldId ++ "-help"), css [ Tw.mt_2, Tw.text_sm, Tw.text_gray_500 ] ] [ text fieldHelp ]
        ]


selectWithLabelAndHelp : List Css.Style -> HtmlId -> String -> String -> List ( String, String ) -> String -> (String -> msg) -> Html msg
selectWithLabelAndHelp styles fieldId fieldLabel fieldHelp fieldOptions fieldValue fieldChange =
    div [ css styles ]
        [ label [ for fieldId, css [ Tw.block, Tw.text_sm, Tw.font_medium, Tw.text_gray_700 ] ] [ text fieldLabel ]
        , div [ css [ Tw.mt_1 ] ]
            [ select [ name fieldId, id fieldId, onInput fieldChange, ariaDescribedby (fieldId ++ "-help"), css [ Tw.form_select, Tw.shadow_sm, Tw.block, Tw.w_full, Tw.border_gray_300, Tw.rounded_md, Css.focus [ Tw.ring_indigo_500, Tw.border_indigo_500 ], Bp.sm [ Tw.text_sm ] ] ]
                (fieldOptions |> List.map (\( optionId, optionLabel ) -> option [ value optionId, selected (optionId == fieldValue) ] [ text optionLabel ]))
            ]
        , p [ id (fieldId ++ "-help"), css [ Tw.mt_2, Tw.text_sm, Tw.text_gray_500 ] ] [ text fieldHelp ]
        ]


checkbox : List Css.Style -> String -> String -> String -> Bool -> msg -> Html msg
checkbox styles fieldId fieldLabel fieldHelp fieldValue fieldChange =
    -- TODO: fieldLabel, replace String with (List (Html msg))
    div [ css ([ Tw.relative, Tw.flex, Tw.items_start ] ++ styles) ]
        [ div [ css [ Tw.flex, Tw.items_center, Tw.h_5 ] ]
            [ input [ type_ "checkbox", name fieldId, id fieldId, checked fieldValue, onClick fieldChange, ariaDescribedby (fieldId ++ "-help"), css [ Tw.form_checkbox, Tw.h_4, Tw.w_4, Tw.text_indigo_600, Tw.border_gray_300, Tw.rounded, Css.focus [ Tw.ring_indigo_500 ] ] ] []
            ]
        , div [ css [ Tw.ml_3, Tw.text_sm ] ]
            [ label [ for fieldId, css [ Tw.font_medium, Tw.text_gray_700 ] ] [ text fieldLabel ]
            , span [ id (fieldId ++ "-help"), css [ Tw.text_gray_500 ] ] [ text (" " ++ fieldHelp) ]
            ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | inputDocState : DocState }


type alias DocState =
    { text : String, select : String, checkbox : Bool }


initDocState : DocState
initDocState =
    { text = "", select = "", checkbox = False }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | inputDocState = s.inputDocState |> transform })


doc : Theme -> Chapter (SharedDocState x)
doc _ =
    Chapter.chapter "Input"
        |> Chapter.renderStatefulComponentList
            [ ( "textWithLabelAndHelp", \{ inputDocState } -> textWithLabelAndHelp [] "email" "email" "Email" "you@example.com" "We'll only use this for spam." inputDocState.text (\value -> updateDocState (\state -> { state | text = value })) )
            , ( "selectWithLabelAndHelp", \{ inputDocState } -> selectWithLabelAndHelp [] "role" "Role" "Choose the correct role" [ ( "admin", "Admin" ), ( "guest", "Guest" ), ( "demo", "Demo" ) ] inputDocState.select (\value -> updateDocState (\state -> { state | select = value })) )
            , ( "checkbox", \{ inputDocState } -> checkbox [] "comments" "Comments" "Get notified when someones posts a comment on a posting." inputDocState.checkbox (updateDocState (\state -> { state | checkbox = not state.checkbox })) )
            ]
