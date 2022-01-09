module Pages.Projects.New exposing (Model, Msg, page)

import Dict
import Gen.Params.Projects.New exposing (Params)
import Gen.Route as Route
import Html.Styled as Styled
import Libs.String as S
import Libs.Task as T
import Models.Project as Project
import Page
import PagesComponents.Projects.New.Models as Models exposing (Msg(..), Tab(..))
import PagesComponents.Projects.New.View exposing (viewNewProject)
import Ports exposing (JsMsg(..), onJsMessage, saveProject, track, trackPage)
import Request
import Services.Lenses exposing (setParsingWithCmd)
import Services.SQLSource as SQLSource exposing (SQLSourceMsg(..))
import Shared
import Tracking
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init req
        , update = update req shared
        , view = view shared
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


init : Request.With Params -> ( Model, Cmd Msg )
init req =
    ( { selectedMenu = "New project"
      , mobileMenuOpen = False
      , selectedTab = req.query |> Dict.get "sample" |> Maybe.map (\_ -> Sample) |> Maybe.withDefault Schema
      , parsing = SQLSource.init Nothing Nothing
      }
    , Cmd.batch
        ((req.query |> Dict.get "sample" |> Maybe.map (\sample -> [ T.send (sample |> SelectSample |> SQLSourceMsg) ]) |> Maybe.withDefault [])
            ++ [ trackPage "new-project" ]
        )
    )



-- UPDATE


update : Request.With Params -> Shared.Model -> Msg -> Model -> ( Model, Cmd Msg )
update req shared msg model =
    case msg of
        SelectMenu menu ->
            ( { model | selectedMenu = menu }, Cmd.none )

        ToggleMobileMenu ->
            ( { model | mobileMenuOpen = not model.mobileMenuOpen }, Cmd.none )

        SelectTab tab ->
            ( { model | selectedTab = tab, parsing = SQLSource.init Nothing Nothing }, Cmd.none )

        SQLSourceMsg message ->
            model |> setParsingWithCmd (SQLSource.update message SQLSourceMsg)

        DropSchema ->
            ( { model | parsing = SQLSource.init Nothing Nothing }, Cmd.none )

        CreateProject projectId source ->
            Project.create projectId (S.unique (shared |> Shared.projects |> List.map .name) source.name) source
                |> (\project ->
                        ( model, Cmd.batch [ saveProject project, track (Tracking.events.createProject project), Request.pushRoute (Route.Projects__Id_ { id = project.id }) req ] )
                   )

        JsMessage jsMsg ->
            ( model, handleJsMessage jsMsg )

        Noop ->
            ( model, Cmd.none )


handleJsMessage : JsMsg -> Cmd Msg
handleJsMessage msg =
    case msg of
        GotLocalFile now projectId sourceId file content ->
            T.send (SQLSource.gotLocalFile now projectId sourceId file content |> SQLSourceMsg)

        GotRemoteFile now projectId sourceId url content sample ->
            T.send (SQLSource.gotRemoteFile now projectId sourceId url content sample |> SQLSourceMsg)

        _ ->
            T.send Noop



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
