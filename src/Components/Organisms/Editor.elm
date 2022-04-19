module Components.Organisms.Editor exposing (doc, poc)

import ElmBook.Actions exposing (logActionWithString)
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
        , attribute "theme" "light"
        , on "input" (Decode.map onInput (Decode.field "detail" Decode.string))
        ]
        []



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Editor"
        |> Chapter.renderComponentList
            [ ( "poc", poc "hello" (logActionWithString "update poc") )
            ]
