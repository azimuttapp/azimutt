module Pages.Projects.New exposing (Model, Msg, page)

import Gen.Params.Projects.New exposing (Params)
import Html.Styled as Styled
import Libs.Task exposing (send)
import Page
import PagesComponents.Projects.New.Models as Models exposing (Msg(..))
import PagesComponents.Projects.New.View exposing (viewNewProject)
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared _ =
    Page.element
        { init = init
        , update = update
        , view = view shared
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { navigationActive = "New project"
      , mobileMenuOpen = False
      }
    , send ReplaceMe
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReplaceMe ->
            ( model, Cmd.none )

        Noop ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Azimutt - Explore your database schema"
    , body = model |> viewNewProject shared |> List.map Styled.toUnstyled
    }
