module Components.Molecules.Slideover exposing (DocState, Model, SharedDocState, doc, initDocState, slideover)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Conf
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, h2, span, text)
import Html.Attributes exposing (class, id, type_)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Attributes exposing (ariaHidden, ariaLabelledby, ariaModal, css, role)
import Libs.Models exposing (Millis)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Tailwind exposing (focus)


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
            B.cond model.isOpen Conf.ui.openDuration Conf.ui.closeDuration
    in
    div [ css [ "fixed inset-0 overflow-hidden z-max", B.cond model.isOpen "" "pointer-events-none" ], ariaLabelledby labelId, role "dialog", ariaModal True ]
        [ div [ class "absolute inset-0 overflow-hidden" ]
            [ div [ onClick model.onClickOverlay, css [ "absolute inset-0 bg-gray-500 bg-opacity-75 transition-opacity ease-in-out", "duration-" ++ String.fromInt duration, B.cond model.isOpen "opacity-100" "opacity-0" ], ariaHidden True ] []
            , div [ class "fixed inset-y-0 right-0 pl-10 max-w-full flex" ]
                [ div [ css [ "w-screen max-w-md transform transition ease-in-out", "duration-" ++ String.fromInt duration, B.cond model.isOpen "translate-x-0" "translate-x-full" ] ]
                    [ div [ id model.id, class "h-full flex flex-col bg-white shadow-xl" ]
                        [ header labelId model.title model.onClickClose
                        , div [ class "flex-1 relative overflow-y-scroll px-4 sm:px-6" ] [ content ]
                        ]
                    ]
                ]
            ]
        ]


header : HtmlId -> String -> msg -> Html msg
header labelId title onClose =
    div [ class "py-6 px-4 sm:px-6" ]
        [ div [ class "flex items-start justify-between" ]
            [ h2 [ class "text-lg font-medium text-gray-900", id labelId ] [ text title ]
            , div [ class "ml-3 h-7 flex items-center" ] [ closeBtn onClose ]
            ]
        ]


closeBtn : msg -> Html msg
closeBtn msg =
    button [ type_ "button", onClick msg, css [ "bg-white rounded-md text-gray-400 hover:text-gray-500", focus "outline-none ring-2 ring-offset-2 ring-indigo-500" ] ]
        [ span [ class "sr-only" ] [ text "Close panel" ]
        , Icon.outline X ""
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
                            (div [ class "absolute inset-0 pb-6 px-4 sm:px-6" ]
                                [ div [ class "h-full border-2 border-dashed border-gray-200", ariaHidden True ]
                                    []
                                ]
                            )
                        ]
                )
            ]
