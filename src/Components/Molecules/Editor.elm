module Components.Molecules.Editor exposing (basic, doc)

import ElmBook.Actions exposing (logActionWithString)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, textarea)
import Html.Attributes exposing (class, id, name, placeholder, rows, value)
import Html.Events exposing (onInput)



-- https://package.elm-lang.org/packages/jxxcarlson/elm-editor/latest


basic : String -> String -> (String -> msg) -> String -> Html msg
basic fieldId fieldValue fieldUpdate fieldPlaceholder =
    textarea
        [ rows 30
        , name fieldId
        , id fieldId
        , value fieldValue
        , onInput fieldUpdate
        , placeholder fieldPlaceholder
        , class "shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
        ]
        []



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Editor"
        |> Chapter.renderComponentList
            [ ( "basic", basic "basic" "" (logActionWithString "basic") "placeholder value" )
            ]
