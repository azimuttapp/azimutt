module PagesComponents.Projects.Updates.PortMsg exposing (handlePortMsg)

import PagesComponents.Projects.Models exposing (Model, Msg)
import Ports exposing (JsMsg(..))


handlePortMsg : JsMsg -> Model -> Cmd Msg
handlePortMsg msg _ =
    case msg of
        _ ->
            Cmd.none
