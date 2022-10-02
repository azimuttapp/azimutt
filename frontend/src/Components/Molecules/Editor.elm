module Components.Molecules.Editor exposing (basic, doc)

import ElmBook.Actions exposing (logActionWithString)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, textarea)
import Html.Attributes exposing (class, id, name, placeholder, rows, value)
import Html.Events exposing (onInput)
import Libs.Tailwind exposing (TwClass)



-- https://package.elm-lang.org/packages/jxxcarlson/elm-editor/latest


basic : String -> String -> (String -> msg) -> String -> Int -> Bool -> Html msg
basic fieldId fieldValue fieldUpdate fieldPlaceholder lines hasErrors =
    let
        colors : TwClass
        colors =
            if hasErrors then
                "text-red-900 placeholder-red-300 border-red-300 focus:border-red-500 focus:ring-red-500"

            else
                "border-gray-300 focus:border-indigo-500 focus:ring-indigo-500"
    in
    textarea
        [ rows lines
        , name fieldId
        , id fieldId
        , value fieldValue
        , onInput fieldUpdate
        , placeholder fieldPlaceholder
        , class ("block w-full shadow-sm rounded-md sm:text-sm " ++ colors)
        ]
        []



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Editor"
        |> Chapter.renderComponentList
            [ ( "basic", basic "basic" "" (logActionWithString "basic") "placeholder value" 3 False )
            , ( "basic with error", basic "basic" "" (logActionWithString "basic") "placeholder value" 3 True )
            ]
