module Components.Molecules.Toast exposing (Content(..), DocState, Model, SharedDocState, SimpleModel, container, doc, initDocState, render)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, p, span, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Libs.Html.Attributes exposing (ariaLive, css)
import Libs.Models.Color as Color exposing (Color)
import Libs.Tailwind exposing (TwClass, focus_ring_500, hover, text_400)


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


render : msg -> Model -> ( String, Html msg )
render onClose model =
    case model.content of
        Simple content ->
            ( model.key, simple onClose model.isOpen content )


simple : msg -> Bool -> SimpleModel -> Html msg
simple onClose isOpen model =
    toast
        (div [ class "flex items-start" ]
            [ div [ class "flex-shrink-0" ] [ Icon.outline model.icon (text_400 model.color) ]
            , div [ class "ml-3 w-0 flex-1 pt-0.5" ]
                [ p [ class "text-sm font-medium text-gray-900" ] [ text model.title ]
                , p [ class "mt-1 text-sm text-gray-500" ] [ text model.message ]
                ]
            , div [ class "ml-4 flex-shrink-0 flex" ]
                [ button [ onClick onClose, css [ "bg-white rounded-md inline-flex text-gray-400", hover [ "text-gray-500" ], focus_ring_500 Color.primary ] ]
                    [ span [ class "sr-only" ] [ text "Close" ]
                    , Icon.solid X ""
                    ]
                ]
            ]
        )
        isOpen


toast : Html msg -> Bool -> Html msg
toast content isOpen =
    let
        toastBlock : TwClass
        toastBlock =
            if isOpen then
                "transition ease-in duration-100 opacity-100 transform translate-y-0 sm:translate-x-2"

            else
                "transition ease-out duration-300 opacity-0 transform translate-y-2 pointer-events-none sm:translate-y-0 sm:translate-x-0"
    in
    div [ css [ "max-w-sm w-full bg-white shadow-lg rounded-lg pointer-events-auto ring-1 ring-black ring-opacity-5 overflow-hidden", toastBlock ] ]
        [ div [ class "p-4" ]
            [ content
            ]
        ]


container : List Model -> (String -> msg) -> Html msg
container toasts close =
    div [ ariaLive "assertive", class "fixed inset-0 flex items-end px-4 py-6 z-max pointer-events-none sm:p-6 sm:items-end" ]
        [ Keyed.node "div"
            [ class "w-full flex flex-col items-center space-y-4 sm:items-start" ]
            (toasts |> List.map (\t -> render (close t.key) t))
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


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Toast"
        |> Chapter.renderStatefulComponentList
            [ ( "simple", \_ -> simple noop True { color = Color.green, icon = CheckCircle, title = "Successfully saved!", message = "Anyone with a link can now view this file." } )
            , ( "add toasts"
              , \{ toastDocState } ->
                    Button.primary3 Color.primary
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
            , ( "container", \{ toastDocState } -> container toastDocState.toasts removeToast )
            ]
