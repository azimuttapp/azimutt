module PagesComponents.Home_.Models exposing (Model, Msg(..))

import Models.Project exposing (Project)
import Ports exposing (JsMsg)


type alias Model =
    { projects : List Project
    , editor : String
    }


type Msg
    = EditorChanged String
    | JsMessage JsMsg
