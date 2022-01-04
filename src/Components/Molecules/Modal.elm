module Components.Molecules.Modal exposing (ConfirmModel, DocState, Model, SharedDocState, closeDuration, confirm, doc, initDocState, modal)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Css
import Dict exposing (Dict)
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div, h3, p, span, text)
import Html.Styled.Attributes exposing (autofocus, css, id)
import Html.Styled.Events exposing (onClick)
import Libs.Dict as D
import Libs.Html.Styled.Attributes exposing (ariaHidden, ariaLabelledby, ariaModal, role)
import Libs.Models exposing (Millis)
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Tailwind.Utilities as Tu
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


openDuration : Millis
openDuration =
    200


closeDuration : Millis
closeDuration =
    300


type alias ConfirmModel msg =
    { id : HtmlId
    , color : Color
    , icon : Icon
    , title : String
    , message : Html msg
    , confirm : String
    , cancel : String
    , onConfirm : msg
    , onCancel : msg
    }


confirm : ConfirmModel msg -> Bool -> Html msg
confirm model isOpen =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"
    in
    modal
        { id = model.id
        , titleId = titleId
        , isOpen = isOpen
        , onBackgroundClick = model.onCancel
        }
        [ div [ css [ Tw.px_6, Tw.pt_6, Bp.sm [ Tw.flex, Tw.items_start ] ] ]
            [ div [ css [ Tw.mx_auto, Tw.flex_shrink_0, Tw.flex, Tw.items_center, Tw.justify_center, Tw.h_12, Tw.w_12, Tw.rounded_full, Color.bg model.color 100, Bp.sm [ Tw.mx_0, Tw.h_10, Tw.w_10 ] ] ]
                [ Icon.outline model.icon [ Color.text model.color 600 ]
                ]
            , div [ css [ Tw.mt_3, Tw.text_center, Bp.sm [ Tw.mt_0, Tw.ml_4, Tw.text_left ] ] ]
                [ h3 [ css [ Tw.text_lg, Tw.leading_6, Tw.font_medium, Tw.text_gray_900 ], id titleId ]
                    [ text model.title ]
                , div [ css [ Tw.mt_2 ] ]
                    [ p [ css [ Tw.text_sm, Tw.text_gray_500 ] ] [ model.message ]
                    ]
                ]
            ]
        , div [ css [ Tw.px_6, Tw.py_3, Tw.mt_6, Tw.bg_gray_50, Bp.sm [ Tw.flex, Tw.items_center, Tw.flex_row_reverse ] ] ]
            [ Button.primary3 model.color [ onClick model.onConfirm, autofocus True, css [ Tw.w_full, Tw.text_base, Bp.sm [ Tw.ml_3, Tw.w_auto, Tw.text_sm ] ] ] [ text model.confirm ]
            , Button.white3 Color.gray [ onClick model.onCancel, css [ Tw.mt_3, Tw.w_full, Tw.text_base, Bp.sm [ Tw.mt_0, Tw.w_auto, Tw.text_sm ] ] ] [ text model.cancel ]
            ]
        ]


type alias Model msg =
    { id : HtmlId
    , titleId : HtmlId
    , isOpen : Bool
    , onBackgroundClick : msg
    }


modal : Model msg -> List (Html msg) -> Html msg
modal model content =
    let
        modalContainer : List Css.Style
        modalContainer =
            if model.isOpen then
                []

            else
                [ Tw.pointer_events_none ]

        backgroundOverlay : List Css.Style
        backgroundOverlay =
            if model.isOpen then
                [ Tw.transition_opacity, Tw.ease_in, Tu.duration openDuration, Tw.opacity_100 ]

            else
                [ Tw.transition_opacity, Tw.ease_out, Tu.duration closeDuration, Tw.opacity_0 ]

        modalPanel : List Css.Style
        modalPanel =
            if model.isOpen then
                [ Tw.transition_all, Tw.ease_in, Tu.duration openDuration, Tw.opacity_100, Tw.translate_y_0, Bp.sm [ Tw.scale_100 ] ]

            else
                [ Tw.transition_all, Tw.ease_out, Tu.duration closeDuration, Tw.opacity_0, Tw.translate_y_4, Bp.sm [ Tw.translate_y_0, Tw.scale_95 ] ]
    in
    div [ ariaLabelledby model.titleId, role "dialog", ariaModal True, css ([ Tw.fixed, Tu.z_max, Tw.inset_0, Tw.overflow_y_auto ] ++ modalContainer) ]
        [ div [ css [ Tw.flex, Tw.items_end, Tw.justify_center, Tw.min_h_screen, Tw.pt_4, Tw.px_4, Tw.pb_20, Tw.text_center, Bp.sm [ Tw.block, Tw.p_0 ] ] ]
            [ div [ ariaHidden True, onClick model.onBackgroundClick, css ([ Tw.fixed, Tw.inset_0, Tw.bg_gray_500, Tw.bg_opacity_75 ] ++ backgroundOverlay) ] []
            , {- This element is to trick the browser into centering the modal contents. -} span [ css [ Tw.hidden, Bp.sm [ Tw.inline_block, Tw.align_middle, Tw.h_screen ] ], ariaHidden True ] [ text "\u{200B}" ]
            , div [ id model.id, css ([ Tw.inline_block, Tw.align_middle, Tw.bg_white, Tw.rounded_lg, Tw.text_left, Tw.overflow_hidden, Tw.shadow_xl, Tw.transform, Bp.sm [ Tw.my_8, Tw.max_w_max, Tw.w_full ] ] ++ modalPanel) ] content
            ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | modalDocState : DocState }


type alias DocState =
    { isOpen : Dict String Bool }


initDocState : DocState
initDocState =
    { isOpen = Dict.empty }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | modalDocState = s.modalDocState |> transform })


component : String -> (Bool -> (Bool -> Msg (SharedDocState x)) -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name buildComponent =
    ( name
    , \{ modalDocState } ->
        buildComponent
            (modalDocState.isOpen |> D.getOrElse name False)
            (\isOpen -> updateDocState (\s -> { s | isOpen = s.isOpen |> Dict.insert name isOpen }))
    )


doc : Theme -> Chapter (SharedDocState x)
doc theme =
    Chapter.chapter "Modal"
        |> Chapter.renderStatefulComponentList
            [ component "confirm"
                (\isOpen setIsOpen ->
                    div []
                        [ Button.primary3 theme.color [ onClick (setIsOpen True) ] [ text "Click me!" ]
                        , confirm
                            { id = "modal-title"
                            , color = Color.red
                            , icon = Exclamation
                            , title = "Deactivate account"
                            , message = text "Are you sure you want to deactivate your account? All of your data will be permanently removed from our servers forever. This action cannot be undone."
                            , confirm = "Deactivate"
                            , cancel = "Cancel"
                            , onConfirm = setIsOpen False
                            , onCancel = setIsOpen False
                            }
                            isOpen
                        ]
                )
            , component "modal"
                (\isOpen setIsOpen ->
                    div []
                        [ Button.primary3 theme.color [ onClick (setIsOpen True) ] [ text "Click me!" ]
                        , modal
                            { id = "modal"
                            , titleId = "modal-title"
                            , isOpen = isOpen
                            , onBackgroundClick = setIsOpen False
                            }
                            [ text "Hello!" ]
                        ]
                )
            ]
