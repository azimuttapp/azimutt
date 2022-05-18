module PagesComponents.Login.Models exposing (Model, Msg(..))

import Ports exposing (LoginInfo)


type alias Model =
    { email : String
    , redirect : Maybe String
    }


type Msg
    = UpdateEmail String
    | Login LoginInfo
