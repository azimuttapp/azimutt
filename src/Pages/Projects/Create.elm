module Pages.Projects.Create exposing (Model, Msg, page)

import Components.Atoms.Loader as Loader
import Conf
import Dict
import Gen.Params.Projects.Create exposing (Params)
import Gen.Route as Route
import Html.Lazy as Lazy
import Libs.Maybe as Maybe
import Libs.Result as Result
import Libs.String as String
import Libs.Task as T
import Models.Project as Project exposing (Project)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId
import Page
import PagesComponents.Projects.Id_.Models.ProjectInfo exposing (ProjectInfo)
import Ports exposing (JsMsg(..))
import Random
import Request
import Services.Backend as Backend
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapDatabaseSourceMCmd, mapJsonSourceMCmd, mapSqlSourceMCmd, mapToastsCmd, setProjectName)
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Shared
import Time
import Track
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init
        , update = update req shared.now shared.conf.backendUrl
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { projects : List ProjectInfo
    , databaseSource : Maybe (DatabaseSource.Model Msg)
    , sqlSource : Maybe (SqlSource.Model Msg)
    , jsonSource : Maybe (JsonSource.Model Msg)
    , projectName : ProjectName

    -- global attrs
    , toasts : Toasts.Model
    }


type Msg
    = InitProject
    | DatabaseSourceMsg DatabaseSource.Msg
    | SqlSourceMsg SqlSource.Msg
    | JsonSourceMsg JsonSource.Msg
    | AmlSourceMsg
    | CreateProject Project
      -- global messages
    | Toast Toasts.Msg
    | JsMessage JsMsg



-- INIT


title : String
title =
    "Creating project..."


init : ( Model, Cmd Msg )
init =
    ( { projects = []
      , databaseSource = Nothing
      , sqlSource = Nothing
      , jsonSource = Nothing
      , projectName = Conf.constants.newProjectName
      , toasts = Toasts.init
      }
    , Cmd.batch
        [ Ports.setMeta
            { title = Just title
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = Route.Projects__Create, query = Dict.empty }
            , html = Just "h-full"
            , body = Just "h-full"
            }
        , Ports.trackPage "create-project"
        , Ports.listProjects
        ]
    )



-- UPDATE


update : Request.With Params -> Time.Posix -> Backend.Url -> Msg -> Model -> ( Model, Cmd Msg )
update req now backendUrl msg model =
    case msg of
        InitProject ->
            ( (req.query |> Dict.get "database" |> Maybe.map (\_ -> { model | databaseSource = Just (DatabaseSource.init Nothing (createProject model)) }))
                |> Maybe.orElse (req.query |> Dict.get "sql" |> Maybe.map (\_ -> { model | sqlSource = Just (SqlSource.init Nothing (Tuple.second >> createProject model)) }))
                |> Maybe.orElse (req.query |> Dict.get "json" |> Maybe.map (\_ -> { model | jsonSource = Just (JsonSource.init Nothing (createProject model)) }))
                |> Maybe.withDefault model
                |> setProjectName (req.query |> Dict.get "name" |> Maybe.withDefault Conf.constants.newProjectName |> String.unique (model.projects |> List.map .name))
            , (req.query |> Dict.get "database" |> Maybe.map (DatabaseSource.GetSchema >> DatabaseSourceMsg >> T.send))
                |> Maybe.orElse (req.query |> Dict.get "sql" |> Maybe.map (SqlSource.GetRemoteFile >> SqlSourceMsg >> T.send))
                |> Maybe.orElse (req.query |> Dict.get "json" |> Maybe.map (JsonSource.GetRemoteFile >> JsonSourceMsg >> T.send))
                |> Maybe.withDefault (AmlSourceMsg |> T.send)
            )

        DatabaseSourceMsg message ->
            model |> mapDatabaseSourceMCmd (DatabaseSource.update DatabaseSourceMsg backendUrl now message)

        JsonSourceMsg message ->
            model |> mapJsonSourceMCmd (JsonSource.update JsonSourceMsg now message)

        SqlSourceMsg message ->
            model |> mapSqlSourceMCmd (SqlSource.update SqlSourceMsg now message)

        AmlSourceMsg ->
            ( model, SourceId.generator |> Random.generate (Source.aml Conf.constants.virtualRelationSourceName now >> Project.create model.projects model.projectName >> CreateProject) )

        CreateProject project ->
            ( model, Cmd.batch [ Ports.createProject project, Ports.track (Track.createProject project), Request.pushRoute (Route.Organization___Project_ { organization = Conf.constants.unknownOrg, project = project.id }) req ] )

        Toast message ->
            model |> mapToastsCmd (Toasts.update Toast message)

        JsMessage message ->
            model |> handleJsMessage message


createProject : Model -> Result String Source -> Msg
createProject model =
    Result.fold (Toasts.error >> Toast) (Project.create model.projects model.projectName >> CreateProject)


handleJsMessage : JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage msg model =
    case msg of
        GotProjects ( _, projects ) ->
            ( { model | projects = projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt)) }, T.send InitProject )

        GotToast level message ->
            ( model, message |> Toasts.create level |> Toast |> T.send )

        _ ->
            ( model, Ports.unhandledJsMsgError msg |> Toasts.create "warning" |> Toast |> T.send )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ Ports.onJsMessage JsMessage ]



-- VIEW


view : Model -> View Msg
view model =
    { title = title, body = [ Loader.fullScreen, Lazy.lazy2 Toasts.view Toast model.toasts ] }
