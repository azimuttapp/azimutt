module Components.Molecules.Modal exposing (DocModel, Model, SharedState, basic, doc, docInit)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Css
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter
import ElmBook.Custom exposing (Msg)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Attribute, Html, button, div, h3, p, span, text)
import Html.Styled.Attributes exposing (css, id, type_)
import Html.Styled.Events exposing (onClick)
import Libs.Html.Styled.Attributes exposing (ariaHidden, ariaLabelledby, ariaModal, role)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias Model msg =
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


basic : Model msg -> Bool -> Html msg
basic model isOpen =
    let
        modalContainer : List Css.Style
        modalContainer =
            if isOpen then
                []

            else
                [ Tw.pointer_events_none ]

        backgroundOverlay : List Css.Style
        backgroundOverlay =
            if isOpen then
                [ Tw.transition_opacity, Tw.opacity_100, Tw.ease_in, Tw.duration_200 ]

            else
                [ Tw.transition_opacity, Tw.opacity_0, Tw.ease_out, Tw.duration_300 ]

        modalPanel : List Css.Style
        modalPanel =
            if isOpen then
                [ Tw.transition_all, Tw.opacity_100, Tw.translate_y_0, Bp.sm [ Tw.scale_100 ], Tw.ease_in, Tw.duration_200 ]

            else
                [ Tw.transition_all, Tw.opacity_0, Tw.translate_y_4, Bp.sm [ Tw.translate_y_0, Tw.scale_95 ], Tw.ease_out, Tw.duration_300 ]
    in
    div [ ariaLabelledby model.id, role "dialog", ariaModal True, css ([ Tw.fixed, Tw.z_10, Tw.inset_0, Tw.overflow_y_auto ] ++ modalContainer) ]
        [ div [ css [ Tw.flex, Tw.items_end, Tw.justify_center, Tw.min_h_screen, Tw.pt_4, Tw.px_4, Tw.pb_20, Tw.text_center, Bp.sm [ Tw.block, Tw.p_0 ] ] ]
            [ div [ ariaHidden True, css ([ Tw.fixed, Tw.inset_0, Tw.bg_gray_500, Tw.bg_opacity_75 ] ++ backgroundOverlay) ] []
            , {- This element is to trick the browser into centering the modal contents. -} span [ css [ Tw.hidden, Bp.sm [ Tw.inline_block, Tw.align_middle, Tw.h_screen ] ], ariaHidden True ] [ text "\u{200B}" ]
            , div [ css ([ Tw.inline_block, Tw.align_bottom, Tw.bg_white, Tw.rounded_lg, Tw.px_4, Tw.pt_5, Tw.pb_4, Tw.text_left, Tw.overflow_hidden, Tw.shadow_xl, Tw.transform, Bp.sm [ Tw.my_8, Tw.align_middle, Tw.max_w_lg, Tw.w_full, Tw.p_6 ] ] ++ modalPanel) ]
                [ div [ css [ Bp.sm [ Tw.flex, Tw.items_start ] ] ]
                    [ div [ css [ Tw.mx_auto, Tw.flex_shrink_0, Tw.flex, Tw.items_center, Tw.justify_center, Tw.h_12, Tw.w_12, Tw.rounded_full, TwColor.render Bg model.color L100, Bp.sm [ Tw.mx_0, Tw.h_10, Tw.w_10 ] ] ]
                        [ Icon.view model.icon [ TwColor.render Text model.color L600 ]
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
                    [ button [ type_ "button", onClick model.onConfirm, css [ Tw.w_full, Tw.inline_flex, Tw.justify_center, Tw.rounded_md, Tw.border, Tw.border_transparent, Tw.shadow_sm, Tw.px_4, Tw.py_2, TwColor.render Bg model.color L600, Tw.text_base, Tw.font_medium, Tw.text_white, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, TwColor.render Ring model.color L500 ], Css.hover [ TwColor.render Bg model.color L700 ], Bp.sm [ Tw.ml_3, Tw.w_auto, Tw.text_sm ] ] ]
                        [ text model.confirm ]
                    , button [ type_ "button", onClick model.onCancel, css [ Tw.mt_3, Tw.w_full, Tw.inline_flex, Tw.justify_center, Tw.rounded_md, Tw.border, Tw.border_gray_300, Tw.shadow_sm, Tw.px_4, Tw.py_2, Tw.bg_white, Tw.text_base, Tw.font_medium, Tw.text_gray_700, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, Tw.ring_indigo_500 ], Css.hover [ Tw.bg_gray_50 ], Bp.sm [ Tw.mt_0, Tw.w_auto, Tw.text_sm ] ] ]
                        [ text model.cancel ]
                    ]
                ]
            ]
        ]


btn : TwColor -> List (Attribute msg) -> List (Html msg) -> Html msg
btn color attrs content =
    button ([ type_ "button", css [ Tw.w_full, Tw.inline_flex, Tw.justify_center, Tw.rounded_md, Tw.border, Tw.border_transparent, Tw.shadow_sm, Tw.px_4, Tw.py_2, TwColor.render Bg color L600, Tw.text_base, Tw.font_medium, Tw.text_white, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, TwColor.render Ring color L500 ], Css.hover [ TwColor.render Bg color L700 ], Bp.sm [ Tw.ml_3, Tw.w_auto, Tw.text_sm ] ] ] ++ attrs) content



-- DOCUMENTATION


type alias SharedState x =
    { x | modal : DocModel }


type alias DocModel =
    { confirmOpen : Bool }


docInit : DocModel
docInit =
    { confirmOpen = False }


update : (DocModel -> DocModel) -> Msg (SharedState x)
update transform =
    Actions.updateState (\s -> { s | modal = s.modal |> transform })


doc : Chapter (SharedState x)
doc =
    Chapter.chapter "Modal"
        |> Chapter.withStatefulComponentList
            [ ( "basic"
              , \{ modal } ->
                    div []
                        [ btn Red [ onClick (update (\m -> { m | confirmOpen = True })) ] [ text "Click me!" ]
                        , basic
                            { id = "modal-title"
                            , icon = Exclamation
                            , color = Red
                            , title = "Deactivate account"
                            , description = "Are you sure you want to deactivate your account? All of your data will be permanently removed from our servers forever. This action cannot be undone."
                            , confirm = "Deactivate"
                            , cancel = "Cancel"
                            , onConfirm = update (\m -> { m | confirmOpen = False })
                            , onCancel = update (\m -> { m | confirmOpen = False })
                            }
                            modal.confirmOpen
                        ]
              )
            ]
        |> Chapter.render """
Modals are quite complex, especially due to their animation.

Here is a basic one:
<component with-label="basic" />

Awesome, isn't it?"""
