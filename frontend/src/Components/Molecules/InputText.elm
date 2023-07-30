module Components.Molecules.InputText exposing (DocState, SharedDocState, doc, docInit, simple)

import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, input)
import Html.Attributes exposing (class, id, name, placeholder, type_, value)
import Html.Events exposing (onInput)
import Libs.Models.HtmlId exposing (HtmlId)


simple : HtmlId -> String -> String -> (String -> msg) -> Html msg
simple fieldId fieldPlaceholder fieldValue fieldChange =
    input [ type_ "text", name fieldId, id fieldId, value fieldValue, onInput fieldChange, placeholder fieldPlaceholder, class "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" ] []



-- DOCUMENTATION


type alias SharedDocState x =
    { x | inputTextDocState : DocState }


type alias DocState =
    { value : String }


docInit : DocState
docInit =
    { value = "" }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | inputTextDocState = s.inputTextDocState |> transform })


component : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name render =
    ( name, \{ inputTextDocState } -> render inputTextDocState )


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "InputText"
        |> Chapter.renderStatefulComponentList
            [ component "simple" (\model -> simple "simple-id" "placeholder" model.value (\v -> updateDocState (\m -> { m | value = v })))
            ]
