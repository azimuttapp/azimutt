module PagesComponents.App.Views.Modals.CreateLayout exposing (viewCreateLayoutModal)

import Conf
import Html exposing (Html, button, div, input, label, text)
import Html.Attributes exposing (autofocus, class, disabled, for, id, type_, value)
import Html.Events exposing (onClick, onInput)
import Libs.Bootstrap exposing (Toggle(..), bsDismiss, bsModal)
import Libs.Html exposing (bText, extLink)
import Models.Project.LayoutName exposing (LayoutName)
import PagesComponents.App.Models exposing (LayoutMsg(..), Msg(..))
import Url exposing (percentEncode)


viewCreateLayoutModal : Maybe LayoutName -> Html Msg
viewCreateLayoutModal newLayout =
    bsModal Conf.ids.newLayoutModal
        "Save layout"
        [ div [ class "row g-3 align-items-center" ]
            [ div [ class "col-auto" ] [ label [ class "col-form-label", for "new-layout-name" ] [ text "Layout name" ] ]
            , div [ class "col-auto" ] [ input [ type_ "text", class "form-control", id "new-layout-name", value (newLayout |> Maybe.withDefault ""), onInput (LNew >> LayoutMsg), autofocus True ] [] ]
            ]
        , div [ class "mt-3" ]
            [ text "Do you like Azimutt ? Consider "
            , extLink (sendTweet "Hi @azimuttapp team, well done with your app, I really like it 👍") [] [ text "sending us a tweet" ]
            , text ", it will help "
            , bText "keep our motivation high"
            , text " 🥰"
            ]
        ]
        [ button [ type_ "button", class "btn btn-secondary", bsDismiss Modal ] [ text "Cancel" ]
        , button [ type_ "button", class "btn btn-primary", bsDismiss Modal, disabled (newLayout == Nothing), onClick (LayoutMsg (LCreate (newLayout |> Maybe.withDefault ""))) ] [ text "Save layout" ]
        ]


sendTweet : String -> String
sendTweet text =
    "https://twitter.com/intent/tweet?text=" ++ percentEncode text
