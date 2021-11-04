module Pages.Projects exposing (Model, Msg, page)

import Gen.Params.Projects exposing (Params)
import Html.Styled as Styled
import Libs.Task exposing (send)
import Page
import PagesComponents.Projects.View exposing (viewProjects)
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ _ =
    Page.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    {}


type Msg
    = ReplaceMe



-- INIT


init : ( Model, Cmd Msg )
init =
    ( {}, send ReplaceMe )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReplaceMe ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view _ =
    { title = "Azimutt - Explore your database schema"
    , body = viewProjects |> List.map Styled.toUnstyled
    }
