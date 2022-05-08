module PagesComponents.Login.Models exposing (Model, Msg(..))

import Ports exposing (JsMsg)


type alias Model =
    { redirect : Maybe String }


type Msg
    = GithubLogin
    | JsMessage JsMsg
