module Components.Molecules.FormLabel exposing (DocState, SharedDocState, bold, doc, docInit, simple)

import Components.Molecules.Select as Select
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, label, text)
import Html.Attributes exposing (class, for)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind exposing (TwClass)


simple : TwClass -> HtmlId -> String -> (HtmlId -> Html msg) -> Html msg
simple styles fieldId fieldLabel field =
    div [ class styles ]
        [ label [ for fieldId, class "mb-1 block text-sm font-medium text-gray-700" ] [ text fieldLabel ]
        , field fieldId
        ]


bold : TwClass -> HtmlId -> String -> (HtmlId -> Html msg) -> Html msg
bold styles fieldId fieldLabel field =
    div [ class styles ]
        [ label [ for fieldId, class "mb-1 block text-base font-medium text-gray-900" ] [ text fieldLabel ]
        , field fieldId
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | formLabelDocState : DocState }


type alias DocState =
    { value : String }


docInit : DocState
docInit =
    { value = "" }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | formLabelDocState = s.formLabelDocState |> transform })


component : String -> (String -> DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name render =
    ( name, \{ formLabelDocState } -> render name formLabelDocState )


sampleHtmlId : HtmlId
sampleHtmlId =
    "simple-id"


sampleSimpleItems : List Select.SimpleItem
sampleSimpleItems =
    [ { value = "United States", label = "United States" }
    , { value = "Canada", label = "Canada" }
    , { value = "Mexico", label = "Mexico" }
    ]


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "FormLabel"
        |> Chapter.renderStatefulComponentList
            [ component "simple" (\name model -> simple "" (sampleHtmlId ++ "-" ++ name) "Location" (\id -> Select.simple id sampleSimpleItems model.value (\v -> updateDocState (\m -> { m | value = v }))))
            , component "bold" (\name model -> bold "" (sampleHtmlId ++ "-" ++ name) "Location" (\id -> Select.simple id sampleSimpleItems model.value (\v -> updateDocState (\m -> { m | value = v }))))
            ]
