module Components.Molecules.Modal exposing (ConfirmModel, DocState, Model, SharedDocState, confirm, doc, initDocState, modal)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, h3, p, span, text)
import Html.Attributes exposing (autofocus, class, id)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Attributes exposing (ariaHidden, ariaLabelledby, ariaModal, css, role)
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind exposing (TwClass, batch, bg_100, sm, text_600)


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
        [ div [ css [ "px-6 pt-6", sm [ "flex items-start" ] ] ]
            [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full", bg_100 model.color, sm [ "mx-0 h-10 w-10" ] ] ]
                [ Icon.outline model.icon (text_600 model.color)
                ]
            , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
                [ h3 [ class "text-lg leading-6 font-medium text-gray-900", id titleId ]
                    [ text model.title ]
                , div [ class "mt-2" ]
                    [ p [ class "text-sm text-gray-500" ] [ model.message ]
                    ]
                ]
            ]
        , div [ css [ "px-6 py-3 mt-6 bg-gray-50", sm [ "flex items-center flex-row-reverse" ] ] ]
            [ Button.primary3 model.color [ onClick model.onConfirm, autofocus True, css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ text model.confirm ]
            , Button.white3 Color.gray [ onClick model.onCancel, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text model.cancel ]
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
                batch [ "transition-all ease-in duration-200 opacity-100 translate-y-0", sm [ "scale-100" ] ]

            else
                batch [ "transition-all ease-out duration-300 opacity-0 translate-y-4", sm [ "translate-y-0 scale-95" ] ]
    in
    div [ ariaLabelledby model.titleId, role "dialog", ariaModal True, css [ "fixed z-max inset-0 overflow-y-auto", B.cond model.isOpen "" "pointer-events-none" ] ]
        [ div [ css [ "flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center", sm [ "block p-0" ] ] ]
            [ div [ ariaHidden True, onClick model.onBackgroundClick, css [ "fixed inset-0 bg-gray-500 bg-opacity-75", backgroundOverlay ] ] []
            , {- This element is to trick the browser into centering the modal contents. -} span [ css [ "hidden", sm [ "inline-block align-middle h-screen" ] ], ariaHidden True ] [ text "\u{200B}" ]
            , div [ id model.id, css [ "inline-block align-middle bg-white rounded-lg text-left overflow-hidden shadow-xl transform", modalPanel, sm [ "my-8 max-w-max w-full" ] ] ] content
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


component : String -> (Bool -> (Bool -> Msg (SharedDocState x)) -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name buildComponent =
    ( name
    , \{ modalDocState } ->
        buildComponent
            (modalDocState.opened == name)
            (\isOpen -> updateDocState (\s -> { s | opened = B.cond isOpen name "" }))
    )


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Modal"
        |> Chapter.renderStatefulComponentList
            [ component "confirm"
                (\isOpen setOpen ->
                    div []
                        [ Button.primary3 Color.primary [ onClick (setOpen True) ] [ text "Click me!" ]
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
                        [ Button.primary3 Color.primary [ onClick (setOpen True) ] [ text "Click me!" ]
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
