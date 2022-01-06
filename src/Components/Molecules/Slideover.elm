module Components.Molecules.Slideover exposing (DocState, Model, SharedDocState, doc, initDocState, slideover)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Modal as Modal
import Css
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, button, div, h2, span, text)
import Html.Styled.Attributes exposing (css, id, type_)
import Html.Styled.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Styled.Attributes exposing (ariaHidden, ariaLabelledby, ariaModal, role)
import Libs.Models exposing (Millis)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Tailwind.Utilities as Tu
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias Model msg =
    { id : HtmlId
    , title : String
    , isOpen : Bool
    , onClickClose : msg
    , onClickOverlay : msg
    }


slideover : Model msg -> Html msg -> Html msg
slideover model content =
    let
        labelId : HtmlId
        labelId =
            model.id ++ "-title"

        duration : Millis
        duration =
            B.cond model.isOpen Modal.openDuration Modal.closeDuration
    in
    div [ css [ Tw.fixed, Tw.inset_0, Tw.overflow_hidden, Tu.z_max, Tu.when (not model.isOpen) [ Tw.pointer_events_none ] ], ariaLabelledby labelId, role "dialog", ariaModal True ]
        [ div [ css [ Tw.absolute, Tw.inset_0, Tw.overflow_hidden ] ]
            [ div [ onClick model.onClickOverlay, css [ Tw.absolute, Tw.inset_0, Tw.bg_gray_500, Tw.bg_opacity_75, Tw.transition_opacity, Tw.ease_in_out, Tu.duration duration, B.cond model.isOpen Tw.opacity_100 Tw.opacity_0 ], ariaHidden True ] []
            , div [ css [ Tw.fixed, Tw.inset_y_0, Tw.right_0, Tw.pl_10, Tw.max_w_full, Tw.flex ] ]
                [ div [ css [ Tw.w_screen, Tw.max_w_md, Tw.transform, Tw.transition, Tw.ease_in_out, Tu.duration duration, B.cond model.isOpen Tw.translate_x_0 Tw.translate_x_full ] ]
                    [ div [ id model.id, css [ Tw.h_full, Tw.flex, Tw.flex_col, Tw.bg_white, Tw.shadow_xl ] ]
                        [ header labelId model.title model.onClickClose
                        , div [ css [ Tw.flex_1, Tw.relative, Tw.overflow_y_scroll, Tw.px_4, Bp.sm [ Tw.px_6 ] ] ] [ content ]
                        ]
                    ]
                ]
            ]
        ]


header : HtmlId -> String -> msg -> Html msg
header labelId title onClose =
    div [ css [ Tw.py_6, Tw.px_4, Bp.sm [ Tw.px_6 ] ] ]
        [ div [ css [ Tw.flex, Tw.items_start, Tw.justify_between ] ]
            [ h2 [ css [ Tw.text_lg, Tw.font_medium, Tw.text_gray_900 ], id labelId ] [ text title ]
            , div [ css [ Tw.ml_3, Tw.h_7, Tw.flex, Tw.items_center ] ] [ closeBtn onClose ]
            ]
        ]


closeBtn : msg -> Html msg
closeBtn msg =
    button [ type_ "button", onClick msg, css [ Tw.bg_white, Tw.rounded_md, Tw.text_gray_400, Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, Tw.ring_indigo_500 ], Css.hover [ Tw.text_gray_500 ] ] ]
        [ span [ css [ Tw.sr_only ] ] [ text "Close panel" ]
        , Icon.outline X []
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | slideoverDocState : DocState }


type alias DocState =
    { opened : String }


initDocState : DocState
initDocState =
    { opened = "" }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | slideoverDocState = s.slideoverDocState |> transform })


component : String -> (Bool -> (Bool -> Msg (SharedDocState x)) -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name buildComponent =
    ( name
    , \{ slideoverDocState } ->
        buildComponent
            (slideoverDocState.opened == name)
            (\isOpen -> updateDocState (\s -> { s | opened = B.cond isOpen name "" }))
    )


doc : Theme -> Chapter (SharedDocState x)
doc theme =
    Chapter.chapter "Slideover"
        |> Chapter.renderStatefulComponentList
            [ component "slideover"
                (\isOpen setOpen ->
                    div []
                        [ Button.primary3 theme.color [ onClick (setOpen True) ] [ text "Click me!" ]
                        , slideover
                            { id = "slideover"
                            , title = "Panel with overlay"
                            , isOpen = isOpen
                            , onClickClose = setOpen False
                            , onClickOverlay = setOpen False
                            }
                            (div [ css [ Tw.absolute, Tw.inset_0, Tw.pb_6, Tw.px_4, Bp.sm [ Tw.px_6 ] ] ]
                                [ div [ css [ Tw.h_full, Tw.border_2, Tw.border_dashed, Tw.border_gray_200 ], ariaHidden True ]
                                    []
                                ]
                            )
                        ]
                )
            ]
