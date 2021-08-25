module PagesComponents.App.Views.Command exposing (viewCommands)

import Conf exposing (conf)
import FontAwesome.Icon exposing (viewIcon)
import FontAwesome.Solid as Icon
import Html exposing (Html, button, div, li, text, ul)
import Html.Attributes exposing (class, id, title, type_)
import Html.Events exposing (onClick)
import Libs.Bootstrap exposing (Toggle(..), bsToggle)
import Libs.Html.Attributes exposing (ariaLabel, ariaLabelledBy, role)
import Models.Project exposing (CanvasProps)
import PagesComponents.App.Models exposing (Msg(..))


viewCommands : Maybe CanvasProps -> Html Msg
viewCommands canvas =
    canvas
        |> Maybe.map
            (\c ->
                div [ class "commands btn-toolbar", role "toolbar", ariaLabel "Diagram commands" ]
                    [ div [ class "btn-group me-2", role "group" ]
                        [ button [ type_ "button", class "btn btn-sm btn-outline-secondary", title "Fit content in view", bsToggle Tooltip, onClick FitContent ] [ viewIcon Icon.expand ]
                        ]
                    , div [ class "btn-group", role "group" ]
                        [ button [ type_ "button", class "btn btn-sm btn-outline-secondary", onClick (Zoom (-c.zoom / 10)) ] [ viewIcon Icon.minus ]
                        , div [ class "btn-group", role "group" ]
                            [ button [ type_ "button", class "btn btn-sm btn-outline-secondary", id "canvas-zoom", bsToggle Dropdown ]
                                [ text (String.fromInt (round (c.zoom * 100)) ++ " %") ]
                            , ul [ class "dropdown-menu", ariaLabelledBy "canvas-zoom" ]
                                [ li [] [ button [ type_ "button", class "dropdown-item", onClick (Zoom (conf.zoom.min - c.zoom)) ] [ text (String.fromFloat (conf.zoom.min * 100) ++ " %") ] ]
                                , li [] [ button [ type_ "button", class "dropdown-item", onClick (Zoom (0.25 - c.zoom)) ] [ text "25 %" ] ]
                                , li [] [ button [ type_ "button", class "dropdown-item", onClick (Zoom (0.5 - c.zoom)) ] [ text "50 %" ] ]
                                , li [] [ button [ type_ "button", class "dropdown-item", onClick (Zoom (1 - c.zoom)) ] [ text "100 %" ] ]
                                , li [] [ button [ type_ "button", class "dropdown-item", onClick (Zoom (1.5 - c.zoom)) ] [ text "150 %" ] ]
                                , li [] [ button [ type_ "button", class "dropdown-item", onClick (Zoom (2 - c.zoom)) ] [ text "200 %" ] ]
                                , li [] [ button [ type_ "button", class "dropdown-item", onClick (Zoom (conf.zoom.max - c.zoom)) ] [ text (String.fromFloat (conf.zoom.max * 100) ++ " %") ] ]
                                ]
                            ]
                        , button [ type_ "button", class "btn btn-sm btn-outline-secondary", onClick (Zoom (c.zoom / 10)) ] [ viewIcon Icon.plus ]
                        ]
                    ]
            )
        |> Maybe.withDefault (div [] [])
