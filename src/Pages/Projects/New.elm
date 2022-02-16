module Pages.Projects.New exposing (Model, Msg, page)

import Conf
import Dict
import Gen.Params.Projects.New exposing (Params)
import Gen.Route as Route
import Libs.Bool as B
import Libs.Maybe as Maybe
import Libs.String as String
import Libs.Task as T
import Models.FileKind exposing (FileKind(..))
import Models.Project as Project
import Page
import PagesComponents.Projects.New.Models as Models exposing (Msg(..), Tab(..))
import PagesComponents.Projects.New.View exposing (viewNewProject)
import Ports exposing (JsMsg(..))
import Request
import Services.Lenses exposing (mapOpenedDialogs, mapProjectImportCmd, mapSqlSourceUploadCmd, setConfirm)
import Services.ProjectImport as ProjectImport
import Services.SqlSourceUpload as SqlSourceUpload exposing (SqlSourceUploadMsg(..))
import Shared
import Time
import Track
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init req
        , update = update req
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
      , openedCollapse = ""
      , projects = []
      , selectedTab =
            (req.query |> Dict.get "sample" |> Maybe.map (\_ -> Sample))
                |> Maybe.withDefault
                    (case req.query |> Dict.get "tab" of
                        Just "schema" ->
                            Schema

                        Just "import" ->
                            Import

                        Just "sample" ->
                            Sample

                        _ ->
                            Schema
                    )
      , sqlSourceUpload = SqlSourceUpload.init Nothing Nothing
      , projectImport = ProjectImport.init
      , confirm = Nothing
      , openedDialogs = []
      }
    , Cmd.batch
        ([ Ports.setClasses { html = "h-full bg-gray-100", body = "h-full" }
         , Ports.trackPage "new-project"
         , Ports.loadProjects
         ]
            ++ (req.query |> Dict.get "sample" |> Maybe.mapOrElse (\sample -> [ T.send (sample |> SelectSample |> SqlSourceUploadMsg) ]) [])
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
            ( { model | selectedTab = tab, sqlSourceUpload = SqlSourceUpload.init Nothing Nothing }, Cmd.none )

        SqlSourceUploadMsg message ->
            model |> mapSqlSourceUploadCmd (SqlSourceUpload.update message SqlSourceUploadMsg)

        DropSchema ->
            ( { model | sqlSourceUpload = SqlSourceUpload.init Nothing Nothing }, Cmd.none )

        CreateProject projectId source ->
            Project.create projectId (String.unique (model.projects |> List.map .name) source.name) source
                |> (\project ->
                        ( model, Cmd.batch [ Ports.saveProject project, Ports.track (Track.createProject project), Request.pushRoute (Route.Projects__Id_ { id = project.id }) req ] )
                   )

        ProjectImportMsg message ->
            model |> mapProjectImportCmd (ProjectImport.update message)

        DropProject ->
            ( { model | projectImport = ProjectImport.init }, Cmd.none )

        ImportProject project ->
            ( model, Cmd.batch [ Ports.saveProject project, Ports.track (Track.importProject project), Request.pushRoute (Route.Projects__Id_ { id = project.id }) req ] )

        ImportNewProject id project ->
            { project | id = id, name = String.unique (model.projects |> List.map .name) project.name }
                |> (\p ->
                        ( model, Cmd.batch [ Ports.saveProject p, Ports.track (Track.importProject p), Request.pushRoute (Route.Projects__Id_ { id = p.id }) req ] )
                   )

        ConfirmOpen confirm ->
            ( model |> setConfirm (Just { id = Conf.ids.confirmDialog, content = confirm }), T.sendAfter 1 (ModalOpen Conf.ids.confirmDialog) )

        ConfirmAnswer answer cmd ->
            ( model |> setConfirm Nothing, B.cond answer cmd Cmd.none )

        ModalOpen id ->
            ( model |> mapOpenedDialogs (\dialogs -> id :: dialogs), Ports.autofocusWithin id )

        ModalClose message ->
            ( model |> mapOpenedDialogs (List.drop 1), T.sendAfter Conf.ui.closeDuration message )

        JsMessage message ->
            model |> handleJsMessage message

        Noop ->
            ( model, Cmd.none )


handleJsMessage : JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage msg model =
    case msg of
        GotProjects ( _, projects ) ->
            ( { model | projects = projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt)) }, Cmd.none )

        GotLocalFile now projectId sourceId file fileKind content ->
            case fileKind of
                SqlSourceFile ->
                    ( model, T.send (SqlSourceUpload.gotLocalFile now projectId sourceId file content |> SqlSourceUploadMsg) )

                ProjectFile ->
                    ( model, T.send (ProjectImport.gotLocalFile projectId content |> ProjectImportMsg) )

        GotRemoteFile now projectId sourceId url content sample ->
            ( model, T.send (SqlSourceUpload.gotRemoteFile now projectId sourceId url content sample |> SqlSourceUploadMsg) )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.onJsMessage JsMessage



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Azimutt - Explore your database schema"
    , body = model |> viewNewProject shared.zone
    }
