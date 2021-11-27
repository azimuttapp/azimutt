module PagesComponents.Projects.Updates.PortMsg exposing (handleJsMsg)

import PagesComponents.Projects.Models exposing (Model, Msg)
import Ports exposing (JsMsg(..))


handleJsMsg : JsMsg -> Model -> Cmd Msg
handleJsMsg msg _ =
    case msg of
        _ ->
            Cmd.none
