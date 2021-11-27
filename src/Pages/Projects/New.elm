module Pages.Projects.New exposing (Model, Msg, page)

import Gen.Params.Projects.New exposing (Params)
import Html.Styled as Styled
import Page
import PagesComponents.Projects.New.Models as Models exposing (Msg(..), Tab(..))
import PagesComponents.Projects.New.Updates.PortMsg exposing (handleJsMsg)
import PagesComponents.Projects.New.View exposing (viewNewProject)
import Ports exposing (JsMsg(..), onJsMessage, readLocalFile)
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
      , tabActive = Schema
      , schemaFile = Nothing
      , schemaFileContent = Nothing
      }
    , Cmd.none
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectMenu menu ->
            ( { model | navigationActive = menu }, Cmd.none )

        ToggleMobileMenu ->
            ( { model | mobileMenuOpen = not model.mobileMenuOpen }, Cmd.none )

        SelectTab tab ->
            ( { model | tabActive = tab }, Cmd.none )

        FileDragOver ->
            ( model, Cmd.none )

        FileDragLeave ->
            ( model, Cmd.none )

        LoadLocalFile file ->
            ( { model | schemaFile = Just file }, readLocalFile Nothing Nothing file )

        FileLoaded projectId sourceInfo fileContent ->
            ( { model | schemaFileContent = Just ( projectId, sourceInfo, fileContent ) }, Cmd.none )

        JsMessage jsMsg ->
            ( model, handleJsMsg jsMsg )

        Noop ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    onJsMessage JsMessage



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Azimutt - Explore your database schema"
    , body = model |> viewNewProject shared |> List.map Styled.toUnstyled
    }
