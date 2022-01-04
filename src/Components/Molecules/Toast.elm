module Components.Molecules.Toast exposing (Content(..), DocState, Model, SharedDocState, SimpleModel, container, doc, initDocState, render)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Css
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, button, div, p, span, text)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick)
import Html.Styled.Keyed as Keyed
import Libs.Html.Styled.Attributes exposing (ariaLive)
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.Theme exposing (Theme)
import Libs.Tailwind.Utilities as Tu
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias Model =
    { key : String, content : Content, isOpen : Bool }


type Content
    = Simple SimpleModel


type alias SimpleModel =
    { color : Color
    , icon : Icon
    , title : String
    , message : String
    }


render : Theme -> msg -> Model -> ( String, Html msg )
render theme onClose model =
    case model.content of
        Simple content ->
            ( model.key, simple theme onClose model.isOpen content )


simple : Theme -> msg -> Bool -> SimpleModel -> Html msg
simple theme onClose isOpen model =
    toast
        (div [ css [ Tw.flex, Tw.items_start ] ]
            [ div [ css [ Tw.flex_shrink_0 ] ] [ Icon.outline model.icon [ Color.text model.color 400 ] ]
            , div [ css [ Tw.ml_3, Tw.w_0, Tw.flex_1, Tw.pt_0_dot_5 ] ]
                [ p [ css [ Tw.text_sm, Tw.font_medium, Tw.text_gray_900 ] ] [ text model.title ]
                , p [ css [ Tw.mt_1, Tw.text_sm, Tw.text_gray_500 ] ] [ text model.message ]
                ]
            , div [ css [ Tw.ml_4, Tw.flex_shrink_0, Tw.flex ] ]
                [ button [ onClick onClose, css [ Tw.bg_white, Tw.rounded_md, Tw.inline_flex, Tw.text_gray_400, Tu.focusRing ( theme.color, 500 ) ( Color.white, 500 ), Css.hover [ Tw.text_gray_500 ] ] ]
                    [ span [ css [ Tw.sr_only ] ] [ text "Close" ]
                    , Icon.solid X []
                    ]
                ]
            ]
        )
        isOpen


toast : Html msg -> Bool -> Html msg
toast content isOpen =
    let
        toastBlock : Css.Style
        toastBlock =
            if isOpen then
                Css.batch [ Tw.transition, Tw.ease_in, Tw.duration_100, Tw.opacity_100, Tw.transform, Tw.translate_y_0, Bp.sm [ Tw.translate_x_2 ] ]

            else
                Css.batch [ Tw.transition, Tw.ease_out, Tw.duration_300, Tw.opacity_0, Tw.transform, Tw.translate_y_2, Bp.sm [ Tw.translate_y_0, Tw.translate_x_0 ], Tw.pointer_events_none ]
    in
    div [ css [ Tw.max_w_sm, Tw.w_full, Tw.bg_white, Tw.shadow_lg, Tw.rounded_lg, Tw.pointer_events_auto, Tw.ring_1, Tw.ring_black, Tw.ring_opacity_5, Tw.overflow_hidden, toastBlock ] ]
        [ div [ css [ Tw.p_4 ] ]
            [ content
            ]
        ]


container : Theme -> List Model -> (String -> msg) -> Html msg
container theme toasts close =
    div [ ariaLive "assertive", css [ Tw.fixed, Tw.inset_0, Tw.flex, Tw.items_end, Tw.px_4, Tw.py_6, Tw.pointer_events_none, Bp.sm [ Tw.p_6, Tw.items_end ] ] ]
        [ Keyed.node "div"
            [ css [ Tw.w_full, Tw.flex, Tw.flex_col, Tw.items_center, Tw.space_y_4, Bp.sm [ Tw.items_start ] ] ]
            (toasts |> List.map (\t -> render theme (close t.key) t))
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | toastDocState : DocState }


type alias DocState =
    { index : Int, toasts : List Model }


initDocState : DocState
initDocState =
    { index = 0, toasts = [] }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | toastDocState = s.toastDocState |> transform })


addToast : Content -> Msg (SharedDocState x)
addToast c =
    updateDocState (\s -> { s | index = s.index + 1, toasts = { key = String.fromInt s.index, content = c, isOpen = True } :: s.toasts })


removeToast : String -> Msg (SharedDocState x)
removeToast key =
    updateDocState (\s -> { s | toasts = s.toasts |> List.filter (\t -> t.key /= key) })


noop : Msg (SharedDocState x)
noop =
    updateDocState identity


doc : Theme -> Chapter (SharedDocState x)
doc theme =
    Chapter.chapter "Toast"
        |> Chapter.renderStatefulComponentList
            [ ( "simple", \_ -> simple theme noop True { color = Color.green, icon = CheckCircle, title = "Successfully saved!", message = "Anyone with a link can now view this file." } )
            , ( "add toasts"
              , \{ toastDocState } ->
                    Button.primary3 theme.color
                        [ onClick
                            (addToast
                                (Simple
                                    { color = Color.green
                                    , icon = CheckCircle
                                    , title = (toastDocState.index |> String.fromInt) ++ ". Successfully saved!"
                                    , message = "Anyone with a link can now view this file."
                                    }
                                )
                            )
                        ]
                        [ text "Simple toast!" ]
              )
            , ( "container", \{ toastDocState } -> container theme toastDocState.toasts removeToast )
            ]
