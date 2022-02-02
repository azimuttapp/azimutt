module Components.Atoms.Input exposing (DocState, SharedDocState, checkbox, doc, initDocState, selectWithLabelAndHelp, textWithLabelAndHelp)

import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, input, label, option, p, select, span, text)
import Html.Attributes exposing (checked, class, for, id, name, placeholder, selected, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Html.Attributes exposing (ariaDescribedby, css)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.Tailwind exposing (TwClass)


textWithLabelAndHelp : TwClass -> HtmlId -> String -> String -> String -> String -> String -> (String -> msg) -> Html msg
textWithLabelAndHelp styles fieldId fieldType fieldLabel fieldPlaceholder fieldHelp fieldValue fieldChange =
    div [ class styles ]
        [ label [ for fieldId, class "block text-sm font-medium text-gray-700" ] [ text fieldLabel ]
        , div [ class "mt-1" ]
            [ input [ type_ fieldType, name fieldId, id fieldId, value fieldValue, onInput fieldChange, placeholder fieldPlaceholder, ariaDescribedby (fieldId ++ "-help"), class "shadow-sm block w-full border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" ] []
            ]
        , p [ id (fieldId ++ "-help"), class "mt-2 text-sm text-gray-500" ] [ text fieldHelp ]
        ]


selectWithLabelAndHelp : TwClass -> HtmlId -> String -> String -> List ( String, String ) -> String -> (String -> msg) -> Html msg
selectWithLabelAndHelp styles fieldId fieldLabel fieldHelp fieldOptions fieldValue fieldChange =
    div [ class styles ]
        [ label [ for fieldId, class "block text-sm font-medium text-gray-700" ] [ text fieldLabel ]
        , div [ class "mt-1" ]
            [ select [ name fieldId, id fieldId, onInput fieldChange, ariaDescribedby (fieldId ++ "-help"), class "shadow-sm block w-full border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" ]
                (fieldOptions |> List.map (\( optionId, optionLabel ) -> option [ value optionId, selected (optionId == fieldValue) ] [ text optionLabel ]))
            ]
        , p [ id (fieldId ++ "-help"), class "mt-2 text-sm text-gray-500" ] [ text fieldHelp ]
        ]


checkbox : TwClass -> String -> String -> String -> Bool -> msg -> Html msg
checkbox styles fieldId fieldLabel fieldHelp fieldValue fieldChange =
    -- TODO: fieldLabel, replace String with (List (Html msg))
    div [ css [ "relative flex items-start", styles ] ]
        [ div [ class "flex items-center h-5" ]
            [ input [ type_ "checkbox", name fieldId, id fieldId, checked fieldValue, onClick fieldChange, ariaDescribedby (fieldId ++ "-help"), class "h-4 w-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" ] []
            ]
        , div [ class "ml-3 text-sm" ]
            [ label [ for fieldId, class "font-medium text-gray-700" ] [ text fieldLabel ]
            , span [ id (fieldId ++ "-help"), class "text-gray-500" ] [ text (" " ++ fieldHelp) ]
            ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | inputDocState : DocState }


type alias DocState =
    { text : String, select : String, checkbox : Bool }


initDocState : DocState
initDocState =
    { text = "", select = "", checkbox = False }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | inputDocState = s.inputDocState |> transform })


doc : Theme -> Chapter (SharedDocState x)
doc _ =
    Chapter.chapter "Input"
        |> Chapter.renderStatefulComponentList
            [ ( "textWithLabelAndHelp", \{ inputDocState } -> textWithLabelAndHelp "" "email" "email" "Email" "you@example.com" "We'll only use this for spam." inputDocState.text (\value -> updateDocState (\state -> { state | text = value })) )
            , ( "selectWithLabelAndHelp", \{ inputDocState } -> selectWithLabelAndHelp "" "role" "Role" "Choose the correct role" [ ( "admin", "Admin" ), ( "guest", "Guest" ), ( "demo", "Demo" ) ] inputDocState.select (\value -> updateDocState (\state -> { state | select = value })) )
            , ( "checkbox", \{ inputDocState } -> checkbox "" "comments" "Comments" "Get notified when someones posts a comment on a posting." inputDocState.checkbox (updateDocState (\state -> { state | checkbox = not state.checkbox })) )
            ]
