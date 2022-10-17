module PagesComponents.Create.Subscriptions exposing (subscriptions)

import PagesComponents.Create.Models exposing (Model, Msg(..))
import Ports


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ Ports.onJsMessage JsMessage ]
