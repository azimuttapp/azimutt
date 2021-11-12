module Pages.Projects exposing (Model, Msg, page)

import Gen.Params.Projects exposing (Params)
import Html.Styled as Styled
import Page
import PagesComponents.Projects.Models as Models exposing (Msg(..), StoredProjects(..))
import PagesComponents.Projects.Updates.PortMsg exposing (handlePortMsg)
import PagesComponents.Projects.View exposing (viewProjects)
import Ports exposing (loadProjects, onJsMessage)
import Request
import Shared
import Time
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
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { activeMenu = Just "Dashboard"
      , profileDropdownOpen = False
      , mobileMenuOpen = False
      , storedProjects = Loading
      , time = { zone = Time.utc, now = Time.millisToPosix 0 }
      }
    , Cmd.batch [ loadProjects ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectMenu menu ->
            ( { model | activeMenu = menu }, Cmd.none )

        ToggleProfileDropdown ->
            ( { model | profileDropdownOpen = not model.profileDropdownOpen }, Cmd.none )

        ToggleMobileMenu ->
            ( { model | mobileMenuOpen = not model.mobileMenuOpen }, Cmd.none )

        ProjectsLoaded projects ->
            ( { model | storedProjects = Loaded projects }, Cmd.none )

        JsMessage m ->
            ( model, model |> handlePortMsg m )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ onJsMessage JsMessage ]



-- VIEW


view : Model -> View Msg
view model =
    { title = "Azimutt - Explore your database schema"
    , body = viewProjects model |> List.map Styled.toUnstyled
    }
