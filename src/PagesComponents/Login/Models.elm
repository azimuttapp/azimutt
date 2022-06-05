module PagesComponents.Login.Models exposing (Model, Msg(..))

import Ports exposing (JsMsg, LoginInfo)
import Services.Toasts as Toasts


type alias Model =
    { email : String
    , redirect : Maybe String
    , toasts : Toasts.Model
    }


type Msg
    = UpdateEmail String
    | Login LoginInfo
    | Toast Toasts.Msg
    | JsMessage JsMsg
