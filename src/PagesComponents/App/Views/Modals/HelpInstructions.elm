module PagesComponents.App.Views.Modals.HelpInstructions exposing (viewHelpModal)

import Conf exposing (conf)
import Html exposing (Html, button, li, text, ul)
import Html.Attributes exposing (class, type_)
import Libs.Bootstrap exposing (Toggle(..), bsDismiss, bsModal)
import Libs.Html exposing (bText, codeText)


viewHelpModal : Html msg
viewHelpModal =
    bsModal conf.ids.helpModal
        "Azimutt cheatsheet"
        [ ul []
            [ li [] [ text "In ", bText "search", text ", you can look for tables and columns, then click on one to show it" ]
            , li [] [ text "Not connected relations on the left are ", bText "incoming foreign keys", text ". Click on the column icon to see tables referencing it and then show them" ]
            , li [] [ text "Not connected relations on the right are ", bText "column foreign keys", text ". Click on the column icon to show referenced table" ]
            , li [] [ text "You can ", bText "hide/show a column", text " with a ", codeText "double click", text " on it" ]
            , li [] [ text "You can ", bText "zoom in/out", text " using scrolling action, ", bText "move tables", text " around by dragging them or even ", bText "move everything", text " by dragging the background" ]
            ]
        ]
        [ button [ type_ "button", class "btn btn-primary", bsDismiss Modal ] [ text "Thanks!" ] ]
