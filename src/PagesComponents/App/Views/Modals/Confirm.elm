module PagesComponents.App.Views.Modals.Confirm exposing (viewConfirm)

import Conf exposing (conf)
import Html exposing (Html, button, div, h5, text)
import Html.Attributes exposing (autofocus, class, id, tabindex, type_)
import Html.Events exposing (onClick)
import Libs.Bootstrap exposing (Toggle(..), bsBackdrop, bsDismiss, bsKeyboard)
import Libs.Html.Attributes exposing (ariaHidden, ariaLabel, ariaLabelledBy)
import PagesComponents.App.Models exposing (Confirm, Msg(..))


viewConfirm : Confirm -> Html Msg
viewConfirm confirm =
    div [ id conf.ids.confirm, class "modal fade", tabindex -1, bsBackdrop "static", bsKeyboard False, ariaLabelledBy (conf.ids.confirm ++ "-label"), ariaHidden True ]
        [ div [ class "modal-dialog modal-dialog-centered" ]
            [ div [ class "modal-content" ]
                [ div [ class "modal-header" ]
                    [ h5 [ class "modal-title", id (conf.ids.confirm ++ "-label") ] [ text "Confirm" ]
                    , button [ type_ "button", class "btn-close", bsDismiss Modal, ariaLabel "Close", onClick (OnConfirm False confirm.cmd) ] []
                    ]
                , div [ class "modal-body" ] [ confirm.content ]
                , div [ class "modal-footer" ]
                    [ button [ class "btn btn-secondary", bsDismiss Modal, onClick (OnConfirm False confirm.cmd) ] [ text "Cancel" ]
                    , button [ class "btn btn-primary", bsDismiss Modal, onClick (OnConfirm True confirm.cmd), autofocus True ] [ text "Ok" ]
                    ]
                ]
            ]
        ]
