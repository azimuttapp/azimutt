module Components.Molecules.Modal2 exposing (ConfirmModel, DocState, Model, SharedDocState, confirm, doc, initDocState, modal)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html exposing (Html, div, h3, p, span, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Html.Styled as Styled exposing (fromUnstyled)
import Html.Styled.Attributes as Styled
import Html.Styled.Events as Styled
import Libs.Bool as B
import Libs.Html.Attributes exposing (ariaHidden, ariaLabelledby, ariaModal, classes, role)
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Tailwind exposing (TwClass, bg_100)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


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
        [ div [ class "px-6 pt-6 sm:flex sm:items-start" ]
            [ div [ classes [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full sm:mx-0 sm:h-10 sm:w-10", bg_100 model.color ] ]
                [ Icon.outline model.icon [ Color.text model.color 600 ] |> Styled.toUnstyled
                ]
            , div [ class "mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left" ]
                [ h3 [ class "text-lg leading-6 font-medium text-gray-900", id titleId ]
                    [ text model.title ]
                , div [ class "mt-2" ]
                    [ p [ class "text-sm text-gray-500" ] [ model.message ]
                    ]
                ]
            ]
        , div [ class "px-6 py-3 mt-6 bg-gray-50 sm:flex sm:items-center sm:flex-row-reverse" ]
            [ Button.primary3 model.color [ Styled.onClick model.onConfirm, Styled.autofocus True, Styled.css [ Tw.w_full, Tw.text_base, Bp.sm [ Tw.ml_3, Tw.w_auto, Tw.text_sm ] ] ] [ Styled.text model.confirm ] |> Styled.toUnstyled
            , Button.white3 Color.gray [ Styled.onClick model.onCancel, Styled.css [ Tw.mt_3, Tw.w_full, Tw.text_base, Bp.sm [ Tw.mt_0, Tw.w_auto, Tw.text_sm ] ] ] [ Styled.text model.cancel ] |> Styled.toUnstyled
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
        backgroundOverlay : TwClass
        backgroundOverlay =
            if model.isOpen then
                "transition-opacity ease-in duration-200 opacity-100"

            else
                "transition-opacity ease-out duration-300 opacity-0"

        modalPanel : TwClass
        modalPanel =
            if model.isOpen then
                "transition-all ease-in duration-200 opacity-100 translate-y-0 sm:scale-100"

            else
                "transition-all ease-out duration-300 opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
    in
    div [ ariaLabelledby model.titleId, role "dialog", ariaModal True, classes [ "fixed z-max inset-0 overflow-y-auto", B.cond model.isOpen "" "pointer-events-none" ] ]
        [ div [ class "flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0" ]
            [ div [ ariaHidden True, onClick model.onBackgroundClick, classes [ "fixed inset-0 bg-gray-500 bg-opacity-75", backgroundOverlay ] ] []
            , {- This element is to trick the browser into centering the modal contents. -} span [ class "hidden sm:inline-block sm:align-middle sm:h-screen", ariaHidden True ] [ text "\u{200B}" ]
            , div [ id model.id, classes [ "inline-block align-middle bg-white rounded-lg text-left overflow-hidden shadow-xl transform sm:my-8 sm:max-w-max sm:w-full", modalPanel ] ] content
            ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | modalDocState : DocState }


type alias DocState =
    { opened : String }


initDocState : DocState
initDocState =
    { opened = "" }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | modalDocState = s.modalDocState |> transform })


component : String -> (Bool -> (Bool -> Msg (SharedDocState x)) -> Html msg) -> ( String, SharedDocState x -> Styled.Html msg )
component name buildComponent =
    ( name
    , \{ modalDocState } ->
        buildComponent
            (modalDocState.opened == name)
            (\isOpen -> updateDocState (\s -> { s | opened = B.cond isOpen name "" }))
            |> fromUnstyled
    )


doc : Theme -> Chapter (SharedDocState x)
doc theme =
    Chapter.chapter "Modal2"
        |> Chapter.renderStatefulComponentList
            [ component "confirm"
                (\isOpen setOpen ->
                    div []
                        [ Button.primary3 theme.color [ Styled.onClick (setOpen True) ] [ Styled.text "Click me!" ] |> Styled.toUnstyled
                        , confirm
                            { id = "modal-title"
                            , color = Color.red
                            , icon = Exclamation
                            , title = "Deactivate account"
                            , message = text "Are you sure you want to deactivate your account? All of your data will be permanently removed from our servers forever. This action cannot be undone."
                            , confirm = "Deactivate"
                            , cancel = "Cancel"
                            , onConfirm = setOpen False
                            , onCancel = setOpen False
                            }
                            isOpen
                        ]
                )
            , component "modal"
                (\isOpen setOpen ->
                    div []
                        [ Button.primary3 theme.color [ Styled.onClick (setOpen True) ] [ Styled.text "Click me!" ] |> Styled.toUnstyled
                        , modal
                            { id = "modal"
                            , titleId = "modal-title"
                            , isOpen = isOpen
                            , onBackgroundClick = setOpen False
                            }
                            [ text "Hello!" ]
                        ]
                )
            ]
