module PagesComponents.App.Views.Modals.CreateLayout exposing (viewCreateLayoutModal)

import Conf exposing (conf)
import Html exposing (Html, a, button, div, input, label, text)
import Html.Attributes exposing (autofocus, class, disabled, for, href, id, rel, target, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bootstrap exposing (Toggle(..), bsDismiss, bsModal)
import Libs.Html exposing (bText)
import Models.Project exposing (LayoutName)
import PagesComponents.App.Models exposing (Msg(..))
import Url exposing (percentEncode)


viewCreateLayoutModal : Maybe LayoutName -> Html Msg
viewCreateLayoutModal newLayout =
    bsModal conf.ids.newLayoutModal
        "Save layout"
        [ div [ class "row g-3 align-items-center" ]
            [ div [ class "col-auto" ] [ label [ class "col-form-label", for "new-layout-name" ] [ text "Layout name" ] ]
            , div [ class "col-auto" ] [ input [ type_ "text", class "form-control", id "new-layout-name", value (newLayout |> Maybe.withDefault ""), onInput NewLayout, autofocus True ] [] ]
            ]
        , div [ class "mt-3" ]
            [ text "Do you like Azimutt ? Consider "
            , a [ href (sendTweet "Hi @azimuttapp team, well done with your app, I really like it 👍"), target "_blank", rel "noopener" ] [ text "sending us a tweet" ]
            , text ", it will help "
            , bText "keep our motivation high"
            , text " 🥰"
            ]
        ]
        [ button [ type_ "button", class "btn btn-secondary", bsDismiss Modal ] [ text "Cancel" ]
        , button [ type_ "button", class "btn btn-primary", bsDismiss Modal, disabled (newLayout == Nothing), onClick (CreateLayout (newLayout |> Maybe.withDefault "")) ] [ text "Save layout" ]
        ]


sendTweet : String -> String
sendTweet text =
    "https://twitter.com/intent/tweet?text=" ++ percentEncode text
