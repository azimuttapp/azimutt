module Components.Molecules.Modal exposing (ConfirmModel, DocState, SharedDocState, confirm, doc, initDocState)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Css
import Dict exposing (Dict)
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div, h3, p, span, text)
import Html.Styled.Attributes exposing (css, id)
import Html.Styled.Events exposing (onClick)
import Libs.Dict as D
import Libs.Html.Styled.Attributes exposing (ariaHidden, ariaLabelledby, ariaModal, role)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias ConfirmModel msg =
    { id : HtmlId
    , icon : Icon
    , color : TwColor
    , title : String
    , description : String
    , confirm : String
    , cancel : String
    , onConfirm : msg
    , onCancel : msg
    }


confirm : ConfirmModel msg -> Bool -> Html msg
confirm model isOpen =
    modal
        { id = model.id
        , isOpen = isOpen
        , onBackgroundClick = model.onCancel
        }
        [ div [ css [ Bp.sm [ Tw.flex, Tw.items_start ] ] ]
            [ div [ css [ Tw.mx_auto, Tw.flex_shrink_0, Tw.flex, Tw.items_center, Tw.justify_center, Tw.h_12, Tw.w_12, Tw.rounded_full, TwColor.render Bg model.color L100, Bp.sm [ Tw.mx_0, Tw.h_10, Tw.w_10 ] ] ]
                [ Icon.outline model.icon [ TwColor.render Text model.color L600 ]
                ]
            , div [ css [ Tw.mt_3, Tw.text_center, Bp.sm [ Tw.mt_0, Tw.ml_4, Tw.text_left ] ] ]
                [ h3 [ css [ Tw.text_lg, Tw.leading_6, Tw.font_medium, Tw.text_gray_900 ], id model.id ]
                    [ text model.title ]
                , div [ css [ Tw.mt_2 ] ]
                    [ p [ css [ Tw.text_sm, Tw.text_gray_500 ] ] [ text model.description ]
                    ]
                ]
            ]
        , div [ css [ Tw.mt_5, Bp.sm [ Tw.mt_4, Tw.flex, Tw.flex_row_reverse ] ] ]
            [ Button.primary3 model.color [ onClick model.onConfirm, css [ Tw.w_full, Tw.text_base, Bp.sm [ Tw.ml_3, Tw.w_auto, Tw.text_sm ] ] ] [ text model.confirm ]
            , Button.white3 model.color [ onClick model.onCancel, css [ Tw.mt_3, Tw.w_full, Tw.text_base, Bp.sm [ Tw.mt_0, Tw.w_auto, Tw.text_sm ] ] ] [ text model.cancel ]
            ]
        ]


type alias Model msg =
    { id : HtmlId
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
                [ Tw.transition_opacity, Tw.ease_in, Tw.duration_200, Tw.opacity_100 ]

            else
                [ Tw.transition_opacity, Tw.ease_out, Tw.duration_300, Tw.opacity_0 ]

        modalPanel : List Css.Style
        modalPanel =
            if model.isOpen then
                [ Tw.transition_all, Tw.ease_in, Tw.duration_200, Tw.opacity_100, Tw.translate_y_0, Bp.sm [ Tw.scale_100 ] ]

            else
                [ Tw.transition_all, Tw.ease_out, Tw.duration_300, Tw.opacity_0, Tw.translate_y_4, Bp.sm [ Tw.translate_y_0, Tw.scale_95 ] ]
    in
    div [ ariaLabelledby model.id, role "dialog", ariaModal True, css ([ Tw.fixed, Tw.z_10, Tw.inset_0, Tw.overflow_y_auto ] ++ modalContainer) ]
        [ div [ css [ Tw.flex, Tw.items_end, Tw.justify_center, Tw.min_h_screen, Tw.pt_4, Tw.px_4, Tw.pb_20, Tw.text_center, Bp.sm [ Tw.block, Tw.p_0 ] ] ]
            [ div [ ariaHidden True, onClick model.onBackgroundClick, css ([ Tw.fixed, Tw.inset_0, Tw.bg_gray_500, Tw.bg_opacity_75 ] ++ backgroundOverlay) ] []
            , {- This element is to trick the browser into centering the modal contents. -} span [ css [ Tw.hidden, Bp.sm [ Tw.inline_block, Tw.align_middle, Tw.h_screen ] ], ariaHidden True ] [ text "\u{200B}" ]
            , div [ css ([ Tw.inline_block, Tw.align_bottom, Tw.bg_white, Tw.rounded_lg, Tw.px_4, Tw.pt_5, Tw.pb_4, Tw.text_left, Tw.overflow_hidden, Tw.shadow_xl, Tw.transform, Bp.sm [ Tw.my_8, Tw.align_middle, Tw.max_w_lg, Tw.w_full, Tw.p_6 ] ] ++ modalPanel) ] content
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


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Modal"
        |> Chapter.renderStatefulComponentList
            [ component "confirm"
                (\isOpen setIsOpen ->
                    div []
                        [ Button.primary3 Indigo [ onClick (setIsOpen True) ] [ text "Click me!" ]
                        , confirm
                            { id = "modal-title"
                            , icon = Exclamation
                            , color = Red
                            , title = "Deactivate account"
                            , description = "Are you sure you want to deactivate your account? All of your data will be permanently removed from our servers forever. This action cannot be undone."
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
                        [ Button.primary3 Indigo [ onClick (setIsOpen True) ] [ text "Click me!" ]
                        , modal
                            { id = "modal-title"
                            , isOpen = isOpen
                            , onBackgroundClick = setIsOpen False
                            }
                            [ text "Hello!" ]
                        ]
                )
            ]
