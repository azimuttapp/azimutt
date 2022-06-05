module PagesComponents.Home_.Models exposing (Model, Msg(..))

import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import Ports exposing (JsMsg)


type alias Model =
    { projects : List ProjectInfo
    }


type Msg
    = JsMessage JsMsg
