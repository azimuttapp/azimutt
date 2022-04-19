module Components.Organisms.Editor exposing (DocState, SharedDocState, doc, initDocState, poc)

import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, node)
import Html.Attributes exposing (attribute)
import Html.Events exposing (on)
import Json.Decode as Decode


poc : String -> (String -> msg) -> Html msg
poc value onInput =
    node "az-editor"
        [ attribute "value" value
        , attribute "language" "javascript"
        , attribute "theme" "vs-dark"
        , on "input" (Decode.map onInput (Decode.field "detail" Decode.string))
        ]
        []


poc1 : String -> (String -> msg) -> Html msg
poc1 value onInput =
    node "az-editor-1"
        [ attribute "value" value
        , attribute "language" "javascript"
        , attribute "theme" "vs-dark"
        , on "input" (Decode.map onInput (Decode.field "detail" Decode.string))
        ]
        []



-- DOCUMENTATION


type alias SharedDocState x =
    { x | editorDocState : DocState }


type alias DocState =
    { value : String }


initDocState : DocState
initDocState =
    { value = "function hello() {\n\talert('Hello world!');\n}" }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | editorDocState = s.editorDocState |> transform })


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Editor"
        |> Chapter.renderStatefulComponentList
            [ ( "poc", \{ editorDocState } -> poc editorDocState.value (\v -> updateDocState (\s -> { s | value = v })) )
            , ( "poc1", \{ editorDocState } -> poc1 editorDocState.value (\v -> updateDocState (\s -> { s | value = v })) )
            ]
