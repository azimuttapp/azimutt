module Pages.Projects.New exposing (Model, Msg, page)

import Dict
import Gen.Params.Projects.New exposing (Params)
import Gen.Route as Route
import Libs.Bool as B
import Libs.Maybe as Maybe
import Libs.String as String
import Libs.Task as T
import Models.Project as Project
import Page
import PagesComponents.Projects.New.Models as Models exposing (Msg(..), Tab(..))
import PagesComponents.Projects.New.View exposing (viewNewProject)
import Ports exposing (JsMsg(..))
import Request
import Services.Lenses exposing (mapParsingCmd)
import Services.SQLSource as SQLSource exposing (SQLSourceMsg(..))
import Shared
import Time
import Track
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ req =
    Page.element
        { init = init req
        , update = update req
        , view = view
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
      , openedCollapse = ""
      , projects = []
      , selectedTab = req.query |> Dict.get "sample" |> Maybe.map (\_ -> Sample) |> Maybe.withDefault Schema
      , parsing = SQLSource.init Nothing Nothing
      }
    , Cmd.batch
        ([ Ports.setClasses { html = "h-full bg-gray-100", body = "h-full" }
         , Ports.trackPage "new-project"
         , Ports.loadProjects
         ]
            ++ (req.query |> Dict.get "sample" |> Maybe.mapOrElse (\sample -> [ T.send (sample |> SelectSample |> SQLSourceMsg) ]) [])
        )
    )



-- UPDATE


update : Request.With Params -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    case msg of
        SelectMenu menu ->
            ( { model | selectedMenu = menu }, Cmd.none )

        ToggleMobileMenu ->
            ( { model | mobileMenuOpen = not model.mobileMenuOpen }, Cmd.none )

        ToggleCollapse id ->
            ( { model | openedCollapse = B.cond (model.openedCollapse == id) "" id }, Cmd.none )

        SelectTab tab ->
            ( { model | selectedTab = tab, parsing = SQLSource.init Nothing Nothing }, Cmd.none )

        SQLSourceMsg message ->
            model |> mapParsingCmd (SQLSource.update message SQLSourceMsg)

        DropSchema ->
            ( { model | parsing = SQLSource.init Nothing Nothing }, Cmd.none )

        CreateProject projectId source ->
            Project.create projectId (String.unique (model.projects |> List.map .name) source.name) source
                |> (\project ->
                        ( model, Cmd.batch [ Ports.saveProject project, Ports.track (Track.createProject project), Request.pushRoute (Route.Projects__Id_ { id = project.id }) req ] )
                   )

        JsMessage message ->
            model |> handleJsMessage message

        Noop ->
            ( model, Cmd.none )


handleJsMessage : JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage msg model =
    case msg of
        GotProjects ( _, projects ) ->
            ( { model | projects = projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt)) }, Cmd.none )

        GotLocalFile now projectId sourceId file content ->
            ( model, T.send (SQLSource.gotLocalFile now projectId sourceId file content |> SQLSourceMsg) )

        GotRemoteFile now projectId sourceId url content sample ->
            ( model, T.send (SQLSource.gotRemoteFile now projectId sourceId url content sample |> SQLSourceMsg) )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.onJsMessage JsMessage



-- VIEW


view : Model -> View Msg
view model =
    { title = "Azimutt - Explore your database schema"
    , body = model |> viewNewProject
    }
