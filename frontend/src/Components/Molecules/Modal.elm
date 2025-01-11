module Components.Molecules.Modal exposing (ConfirmModel, DocState, Model, PromptModel, SharedDocState, confirm, doc, docInit, modal, prompt)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, h3, input, p, span, text, textarea)
import Html.Attributes exposing (autofocus, class, cols, id, name, placeholder, rows, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bool as B
import Libs.Html.Attributes exposing (ariaHidden, ariaLabelledby, ariaModal, css, role)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Tw exposing (Color, TwClass, batch, bg_100, focus, sm, text_600)


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
        , div [ css [ "px-6 py-3 mt-6 bg-gray-50 rounded-b-lg", sm [ "flex items-center flex-row-reverse" ] ] ]
            [ Button.primary3 model.color [ onClick model.onConfirm, autofocus True, css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ text model.confirm ]
            , Button.white3 Tw.gray [ onClick model.onCancel, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text model.cancel ]
            ]
        ]


type alias PromptModel msg =
    { id : HtmlId
    , color : Color
    , icon : Maybe Icon
    , title : String
    , message : Html msg
    , placeholder : String
    , value : String
    , multiline : Bool
    , onUpdate : String -> msg
    , confirm : String
    , cancel : String
    , onConfirm : msg
    , onCancel : msg
    }


prompt : PromptModel msg -> Bool -> Html msg
prompt model isOpen =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"

        fieldId : HtmlId
        fieldId =
            model.id ++ "-input"
    in
    modal
        { id = model.id
        , titleId = titleId
        , isOpen = isOpen
        , onBackgroundClick = model.onCancel
        }
        [ div [ css [ "px-6 pt-6", sm [ "flex items-start" ] ] ]
            [ model.icon
                |> Maybe.mapOrElse
                    (\icon ->
                        div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full", bg_100 model.color, sm [ "mx-0 h-10 w-10" ] ] ]
                            [ Icon.outline icon (text_600 model.color)
                            ]
                    )
                    (text "")
            , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
                [ h3 [ class "text-lg leading-6 font-medium text-gray-900", id titleId ]
                    [ text model.title ]
                , div [ class "mt-2" ]
                    [ p [ class "text-sm text-gray-500" ] [ model.message ]
                    ]
                , div [ class "mt-1" ]
                    [ if model.multiline then
                        let
                            lines : List String
                            lines =
                                model.value |> String.split "\n"

                            maxCol : Int
                            maxCol =
                                lines |> List.map String.length |> List.maximum |> Maybe.withDefault 0
                        in
                        textarea [ name fieldId, id fieldId, rows (lines |> List.length |> max 5 |> min 30), cols (maxCol |> max 40 |> min 120), value model.value, onInput model.onUpdate, placeholder model.placeholder, autofocus True, css [ "shadow-sm block w-full border-gray-300 rounded-md", focus [ "ring-indigo-500 border-indigo-500" ], sm [ "text-sm" ] ] ] []

                      else
                        input [ type_ "text", name fieldId, id fieldId, value model.value, onInput model.onUpdate, placeholder model.placeholder, autofocus True, css [ "shadow-sm block w-full border-gray-300 rounded-md", focus [ "ring-indigo-500 border-indigo-500" ], sm [ "text-sm" ] ] ] []
                    ]
                ]
            ]
        , div [ css [ "px-6 py-3 mt-6 bg-gray-50 rounded-b-lg", sm [ "flex items-center flex-row-reverse" ] ] ]
            [ Button.primary3 model.color [ onClick model.onConfirm, autofocus True, css [ "w-full text-base", sm [ "ml-3 w-auto text-sm" ] ] ] [ text model.confirm ]
            , Button.white3 Tw.gray [ onClick model.onCancel, css [ "mt-3 w-full text-base", sm [ "mt-0 w-auto text-sm" ] ] ] [ text model.cancel ]
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
            , div [ id model.id, css [ "inline-block align-middle bg-white rounded-lg text-left shadow-xl transform", modalPanel, sm [ "my-8 max-w-max w-full" ] ] ] content
            ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | modalDocState : DocState }


type alias DocState =
    { opened : String, input : String }


docInit : DocState
docInit =
    { opened = "", input = "" }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | modalDocState = s.modalDocState |> transform })


setOpened : String -> Msg (SharedDocState x)
setOpened value =
    updateDocState (\s -> { s | opened = value })


setInput : String -> Msg (SharedDocState x)
setInput value =
    updateDocState (\s -> { s | input = value })


component : String -> (String -> DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name buildComponent =
    ( name, \{ modalDocState } -> buildComponent name modalDocState )


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Modal"
        |> Chapter.renderStatefulComponentList
            [ component "confirm"
                (\name state ->
                    div []
                        [ Button.primary3 Tw.primary [ onClick (setOpened name) ] [ text "Click me!" ]
                        , confirm
                            { id = "modal-title"
                            , color = Tw.red
                            , icon = Exclamation
                            , title = "Deactivate account"
                            , message = text "Are you sure you want to deactivate your account? All of your data will be permanently removed from our servers forever. This action cannot be undone."
                            , confirm = "Deactivate"
                            , cancel = "Cancel"
                            , onConfirm = setOpened ""
                            , onCancel = setOpened ""
                            }
                            (state.opened == name)
                        ]
                )
            , component "prompt"
                (\name state ->
                    div []
                        [ Button.primary3 Tw.primary [ onClick (setOpened name) ] [ text "Click me!" ]
                        , prompt
                            { id = "modal-title"
                            , color = Tw.blue
                            , icon = Just QuestionMarkCircle
                            , title = "Please enter your name"
                            , message = text "This will be useful later ;)"
                            , placeholder = ""
                            , value = state.input
                            , multiline = False
                            , onUpdate = setInput
                            , confirm = "Ok"
                            , cancel = "Cancel"
                            , onConfirm = setOpened ""
                            , onCancel = setOpened ""
                            }
                            (state.opened == name)
                        ]
                )
            , component "modal"
                (\name state ->
                    div []
                        [ Button.primary3 Tw.primary [ onClick (setOpened name) ] [ text "Click me!" ]
                        , modal
                            { id = "modal"
                            , titleId = "modal-title"
                            , isOpen = state.opened == name
                            , onBackgroundClick = setOpened ""
                            }
                            [ text "Hello!" ]
                        ]
                )
            ]
