module Pages.Projects exposing (Model, Msg, page)

import Gen.Params.Projects exposing (Params)
import Html.Styled as Styled
import Page
import PagesComponents.Projects.Models as Models exposing (Msg(..))
import PagesComponents.Projects.View exposing (viewProjects)
import Ports
import Request
import Shared
import Tracking
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
    ( { navigationActive = "Dashboard"
      , mobileMenuOpen = False
      }
    , Cmd.batch [ Ports.loadProjects ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectMenu menu ->
            ( { model | navigationActive = menu }, Cmd.none )

        ToggleMobileMenu ->
            ( { model | mobileMenuOpen = not model.mobileMenuOpen }, Cmd.none )

        DeleteProject project ->
            ( model, Cmd.batch [ Ports.dropProject project, Ports.track (Tracking.events.deleteProject project) ] )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Azimutt - Explore your database schema"
    , body = model |> viewProjects shared |> List.map Styled.toUnstyled
    }
