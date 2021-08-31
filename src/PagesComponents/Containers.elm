module PagesComponents.Containers exposing (root)

import FontAwesome.Styles as Icon
import Html exposing (Html, div)
import Html.Attributes exposing (class, id)


root : List (Html msg) -> List (Html msg)
root children =
    [ Icon.css ] ++ children ++ [ viewToasts ]


viewToasts : Html msg
viewToasts =
    div [ id "toast-container", class "toast-container position-fixed bottom-0 end-0 p-3" ] []
