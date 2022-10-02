module Components.Atoms.Loader exposing (doc, fullScreen)

import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div)
import Html.Attributes exposing (class)


fullScreen : Html msg
fullScreen =
    div [ class "flex justify-center items-center h-screen" ]
        [ div [ class "animate-spin rounded-full h-32 w-32 border-t-2 border-b-2 border-primary-500" ] []
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "Loader"
        |> Chapter.renderComponentList
            [ ( "fullScreen", fullScreen )
            ]
