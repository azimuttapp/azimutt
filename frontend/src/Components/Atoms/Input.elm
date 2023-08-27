module Components.Atoms.Input exposing (DocState, SharedDocState, checkbox, checkboxBold, checkboxWithLabelAndHelp, doc, docInit, selectWithLabelAndHelp, textWithLabelAndHelp)

import ElmBook exposing (Msg)
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, input, label, option, p, select, span, text)
import Html.Attributes exposing (checked, class, for, id, name, placeholder, selected, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Html.Attributes exposing (ariaDescribedby, css)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind exposing (TwClass, focus, sm)


textWithLabelAndHelp : TwClass -> HtmlId -> String -> String -> String -> String -> (String -> msg) -> Html msg
textWithLabelAndHelp styles fieldId fieldLabel fieldHelp fieldPlaceholder fieldValue fieldChange =
    div [ class styles ]
        [ label [ for fieldId, class "block" ]
            [ span [ class "text-sm font-medium text-gray-700" ] [ text fieldLabel ]
            , p [ id (fieldId ++ "-help"), class "text-sm text-gray-500" ] [ text fieldHelp ]
            ]
        , div [ class "mt-1" ]
            [ input [ type_ "text", name fieldId, id fieldId, value fieldValue, onInput fieldChange, placeholder fieldPlaceholder, ariaDescribedby (fieldId ++ "-help"), css [ "shadow-sm block w-full border-gray-300 rounded-md", focus [ "ring-indigo-500 border-indigo-500" ], sm [ "text-sm" ] ] ] []
            ]
        ]


selectWithLabelAndHelp : TwClass -> HtmlId -> String -> String -> List ( String, String ) -> String -> (String -> msg) -> Html msg
selectWithLabelAndHelp styles fieldId fieldLabel fieldHelp fieldOptions fieldValue fieldChange =
    div [ class styles ]
        [ label [ for fieldId, class "block" ]
            [ span [ class "text-sm font-medium text-gray-700" ] [ text fieldLabel ]
            , p [ id (fieldId ++ "-help"), class "text-sm text-gray-500" ] [ text fieldHelp ]
            ]
        , div [ class "mt-1" ]
            [ select [ name fieldId, id fieldId, onInput fieldChange, ariaDescribedby (fieldId ++ "-help"), css [ "shadow-sm block w-full border-gray-300 rounded-md", focus [ "ring-indigo-500 border-indigo-500" ], sm [ "text-sm" ] ] ]
                (fieldOptions |> List.map (\( optionId, optionLabel ) -> option [ value optionId, selected (optionId == fieldValue) ] [ text optionLabel ]))
            ]
        ]


checkboxWithLabelAndHelp : TwClass -> HtmlId -> String -> String -> String -> Bool -> msg -> Html msg
checkboxWithLabelAndHelp styles fieldId fieldLabel fieldHelp fieldDescription fieldValue fieldChange =
    div [ class styles ]
        [ label [ for fieldId, class "block" ]
            [ span [ class "text-sm font-medium text-gray-700" ] [ text fieldLabel ]
            , p [ id (fieldId ++ "-help"), class "text-sm text-gray-500" ] [ text fieldHelp ]
            ]
        , checkbox "mt-1" fieldId fieldDescription fieldValue fieldChange
        ]


checkbox : TwClass -> String -> String -> Bool -> msg -> Html msg
checkbox styles fieldId fieldLabel fieldValue fieldChange =
    -- TODO: fieldLabel, replace String with (List (Html msg))
    div [ css [ "relative flex items-start", styles ] ]
        [ div [ class "flex items-center h-5" ]
            [ input [ type_ "checkbox", name fieldId, id fieldId, checked fieldValue, onClick fieldChange, ariaDescribedby (fieldId ++ "-help"), css [ "h-4 w-4 text-indigo-600 border-gray-300 rounded", focus [ "ring-indigo-500" ] ] ] []
            ]
        , div [ class "ml-3 text-sm" ]
            [ label [ for fieldId, class "text-gray-700" ] [ text fieldLabel ]
            ]
        ]


checkboxBold : TwClass -> String -> String -> String -> Bool -> msg -> Html msg
checkboxBold styles fieldId fieldLabel fieldHelp fieldValue fieldChange =
    -- TODO: fieldLabel, replace String with (List (Html msg))
    div [ css [ "relative flex items-start", styles ] ]
        [ div [ class "flex items-center h-5" ]
            [ input [ type_ "checkbox", name fieldId, id fieldId, checked fieldValue, onClick fieldChange, ariaDescribedby (fieldId ++ "-help"), css [ "h-4 w-4 text-indigo-600 border-gray-300 rounded", focus [ "ring-indigo-500" ] ] ] []
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


docInit : DocState
docInit =
    { text = "", select = "", checkbox = False }


updateDocState : (DocState -> DocState) -> Msg (SharedDocState x)
updateDocState transform =
    Actions.updateState (\s -> { s | inputDocState = s.inputDocState |> transform })


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Input"
        |> Chapter.renderStatefulComponentList
            [ ( "textWithLabelAndHelp", \{ inputDocState } -> textWithLabelAndHelp "" "email" "Email" "We'll only use this for spam." "you@example.com" inputDocState.text (\value -> updateDocState (\state -> { state | text = value })) )
            , ( "selectWithLabelAndHelp", \{ inputDocState } -> selectWithLabelAndHelp "" "role" "Role" "Choose the correct role" [ ( "admin", "Admin" ), ( "guest", "Guest" ), ( "demo", "Demo" ) ] inputDocState.select (\value -> updateDocState (\state -> { state | select = value })) )
            , ( "checkboxWithLabelAndHelp", \{ inputDocState } -> checkboxWithLabelAndHelp "" "comments" "Comments" "Get notified when someones posts a comment on a posting." "Check this!" inputDocState.checkbox (updateDocState (\state -> { state | checkbox = not state.checkbox })) )
            , ( "checkbox", \{ inputDocState } -> checkbox "" "comments" "Comments" inputDocState.checkbox (updateDocState (\state -> { state | checkbox = not state.checkbox })) )
            , ( "checkboxBold", \{ inputDocState } -> checkboxBold "" "comments" "Comments" "Get notified when someones posts a comment on a posting." inputDocState.checkbox (updateDocState (\state -> { state | checkbox = not state.checkbox })) )
            ]
