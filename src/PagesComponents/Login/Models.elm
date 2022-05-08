module PagesComponents.Login.Models exposing (Model, Msg(..))


type alias Model =
    { redirect : Maybe String }


type Msg
    = GithubLogin
