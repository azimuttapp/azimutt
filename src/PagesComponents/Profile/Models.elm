module PagesComponents.Profile.Models exposing (Model, Msg(..))

import Ports exposing (JsMsg)


type alias Model =
    {}


type Msg
    = JsMessage JsMsg
    | Noop String
