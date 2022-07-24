module Pages.Projects.New exposing (Model, Msg, page)

import Components.Molecules.Dropdown as Dropdown
import Conf exposing (SampleSchema)
import Dict
import Gen.Params.Projects.New exposing (Params)
import Gen.Route as Route
import Libs.Bool as B
import Libs.Json.Decode as Decode
import Libs.Maybe as Maybe
import Libs.Random as Random
import Libs.String as String
import Libs.Task as T
import Models.Project as Project
import Models.Project.ProjectId as ProjectId
import Models.Project.ProjectStorage as ProjectStorage
import Models.Project.Source as Source
import Models.Project.SourceId as SourceId
import Models.SourceInfo as SourceInfo
import Page
import PagesComponents.Projects.New.Models as Models exposing (Msg(..), Tab(..))
import PagesComponents.Projects.New.View exposing (viewNewProject)
import Ports exposing (JsMsg(..))
import Random
import Request
import Services.Backend as Backend
import Services.DatabaseSource as DatabaseSource
import Services.ImportProject as ImportProject
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapDatabaseSourceMCmd, mapImportProjectM, mapImportProjectMCmd, mapJsonSourceMCmd, mapOpenedDialogs, mapSampleProjectM, mapSampleProjectMCmd, mapSqlSourceMCmd, mapToastsCmd, setConfirm)
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Shared
import Time
import Track
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init req
        , update = update req shared.now shared.conf.backendUrl
        , view = view shared req
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


title : String
title =
    Conf.constants.defaultTitle


init : Request.With Params -> ( Model, Cmd Msg )
init req =
    let
        sample : Maybe SampleSchema
        sample =
            req.query |> Dict.get "sample" |> Maybe.andThen (\key -> Conf.schemaSamples |> Dict.get key)

        tab : Maybe String
        tab =
            req.query |> Dict.get "tab"

        selectedTab : Tab
        selectedTab =
            (sample |> Maybe.map (\_ -> TabSamples))
                |> Maybe.withDefault
                    (case tab of
                        Just "database" ->
                            TabDatabase

                        Just "sql" ->
                            TabSql

                        Just "json" ->
                            TabJson

                        Just "project" ->
                            TabProject

                        Just "samples" ->
                            TabSamples

                        -- legacy names:
                        Just "schema" ->
                            TabSql

                        Just "import" ->
                            TabProject

                        Just "sample" ->
                            TabSamples

                        _ ->
                            TabDatabase
                    )
    in
    ( { selectedMenu = "New project"
      , mobileMenuOpen = False
      , openedCollapse = ""
      , projects = []
      , selectedTab = TabSamples
      , sqlSource = Nothing
      , databaseSource = Nothing
      , jsonSource = Nothing
      , importProject = Nothing
      , sampleProject = Nothing
      , openedDropdown = ""
      , toasts = Toasts.init
      , confirm = Nothing
      , openedDialogs = []
      }
        |> initTab selectedTab
    , Cmd.batch
        ([ Ports.setMeta
            { title = Just title
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = Route.Projects__New, query = Dict.empty }
            , html = Just "h-full bg-gray-100"
            , body = Just "h-full"
            }
         , Ports.trackPage "new-project"
         , Ports.listProjects
         ]
            ++ (sample |> Maybe.mapOrElse (\s -> [ T.send (SampleProjectMsg (ImportProject.GetRemoteFile s.url (Just s.key))) ]) [])
        )
    )


initTab : Tab -> Model -> Model
initTab tab model =
    let
        clean : Model
        clean =
            { model | selectedTab = tab, sqlSource = Nothing, databaseSource = Nothing, jsonSource = Nothing, importProject = Nothing, sampleProject = Nothing }
    in
    case tab of
        TabDatabase ->
            { clean | databaseSource = Just (DatabaseSource.init Conf.schema.default Nothing (\_ -> Noop "select-tab-database-source")) }

        TabSql ->
            { clean | sqlSource = Just (SqlSource.init Conf.schema.default Nothing (\_ -> Noop "select-tab-sql-source")) }

        TabJson ->
            { clean | jsonSource = Just (JsonSource.init Conf.schema.default Nothing (\_ -> Noop "select-tab-json-source")) }

        TabEmptyProject ->
            clean

        TabProject ->
            { clean | importProject = Just ImportProject.init }

        TabSamples ->
            { clean | sampleProject = Just ImportProject.init }



-- UPDATE


update : Request.With Params -> Time.Posix -> Backend.Url -> Msg -> Model -> ( Model, Cmd Msg )
update req now backendUrl msg model =
    case msg of
        SelectMenu menu ->
            ( { model | selectedMenu = menu }, Cmd.none )

        Logout ->
            ( { model | projects = model.projects |> List.filter (\p -> p.storage == ProjectStorage.Browser) }, Ports.logout )

        ToggleCollapse id ->
            ( { model | openedCollapse = B.cond (model.openedCollapse == id) "" id }, Cmd.none )

        SelectTab tab ->
            ( model |> initTab tab, Cmd.none )

        DatabaseSourceMsg message ->
            (model |> mapDatabaseSourceMCmd (DatabaseSource.update DatabaseSourceMsg backendUrl now message))
                |> Tuple.mapSecond
                    (\cmd ->
                        case message of
                            DatabaseSource.BuildSource _ ->
                                Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]

                            _ ->
                                cmd
                    )

        DatabaseSourceDrop ->
            ( { model | databaseSource = DatabaseSource.init Conf.schema.default Nothing (\_ -> Noop "drop-database-source") |> Just }, Cmd.none )

        SqlSourceMsg message ->
            (model |> mapSqlSourceMCmd (SqlSource.update SqlSourceMsg now message))
                |> Tuple.mapSecond
                    (\cmd ->
                        case message of
                            SqlSource.BuildSource ->
                                Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]

                            _ ->
                                cmd
                    )

        SqlSourceDrop ->
            ( { model | sqlSource = SqlSource.init Conf.schema.default Nothing (\_ -> Noop "drop-sql-source") |> Just }, Cmd.none )

        JsonSourceMsg message ->
            (model |> mapJsonSourceMCmd (JsonSource.update JsonSourceMsg now message))
                |> Tuple.mapSecond
                    (\cmd ->
                        case message of
                            JsonSource.BuildSource ->
                                Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]

                            _ ->
                                cmd
                    )

        JsonSourceDrop ->
            ( { model | jsonSource = JsonSource.init Conf.schema.default Nothing (\_ -> Noop "drop-json-source") |> Just }, Cmd.none )

        ImportProjectMsg message ->
            (model |> mapImportProjectMCmd (ImportProject.update ImportProjectMsg message))
                |> Tuple.mapSecond
                    (\cmd ->
                        case message of
                            ImportProject.BuildProject ->
                                Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]

                            _ ->
                                cmd
                    )

        ImportProjectDrop ->
            ( model |> mapImportProjectM (\_ -> ImportProject.init), Cmd.none )

        SampleProjectMsg message ->
            (model |> mapSampleProjectMCmd (ImportProject.update SampleProjectMsg message))
                |> Tuple.mapSecond
                    (\cmd ->
                        case message of
                            ImportProject.BuildProject ->
                                Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]

                            _ ->
                                cmd
                    )

        SampleProjectDrop ->
            ( model |> mapSampleProjectM (\_ -> ImportProject.init), Cmd.none )

        CreateProject project ->
            ( model, Cmd.batch [ Ports.createProject project, Ports.track (Track.createProject project), Request.pushRoute (Route.Projects__Id_ { id = project.id }) req ] )

        CreateProjectNew project ->
            ( model, ProjectId.generator |> Random.generate (\projectId -> project |> Project.duplicate (model.projects |> List.map .name) projectId |> CreateProject) )

        CreateProjectFromSource source ->
            ( model, ProjectId.generator |> Random.generate (\projectId -> Project.create projectId (String.unique (model.projects |> List.map .name) source.name) source |> CreateProject) )

        CreateEmptyProject name ->
            ( model
            , Random.generate2
                (\projectId sourceId ->
                    Source.aml sourceId Conf.constants.virtualRelationSourceName now
                        |> (\source -> Project.create projectId (String.unique (model.projects |> List.map .name) name) source |> CreateProject)
                )
                ProjectId.generator
                SourceId.generator
            )

        DropdownToggle id ->
            ( model |> Dropdown.update id, Cmd.none )

        Toast message ->
            model |> mapToastsCmd (Toasts.update Toast message)

        ConfirmOpen confirm ->
            ( model |> setConfirm (Just { id = Conf.ids.confirmDialog, content = confirm }), T.sendAfter 1 (ModalOpen Conf.ids.confirmDialog) )

        ConfirmAnswer answer cmd ->
            ( model |> setConfirm Nothing, B.cond answer cmd Cmd.none )

        ModalOpen id ->
            ( model |> mapOpenedDialogs (\dialogs -> id :: dialogs), Ports.autofocusWithin id )

        ModalClose message ->
            ( model |> mapOpenedDialogs (List.drop 1), T.sendAfter Conf.ui.closeDuration message )

        JsMessage message ->
            model |> handleJsMessage now message

        Noop _ ->
            ( model, Cmd.none )


handleJsMessage : Time.Posix -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage now msg model =
    case msg of
        GotProjects ( _, projects ) ->
            ( { model | projects = projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt)) }, Cmd.none )

        GotLocalFile kind file content ->
            if kind == ImportProject.kind then
                ( model, T.send (content |> ImportProject.GotFile |> ImportProjectMsg) )

            else if kind == SqlSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> SqlSource.GotFile (SourceInfo.sqlLocal now sourceId file) |> SqlSourceMsg) )

            else if kind == JsonSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> JsonSource.GotFile (SourceInfo.jsonLocal now sourceId file) |> JsonSourceMsg) )

            else
                ( model, Toasts.error Toast ("Unhandled local file for " ++ kind ++ " source") )

        GotToast level message ->
            ( model, Toasts.create Toast level message )

        GotLogin _ ->
            -- handled in shared
            ( model, Cmd.none )

        Error err ->
            ( model, Cmd.batch [ Toasts.error Toast ("Unable to decode JavaScript message: " ++ Decode.errorToHtml err), Ports.trackJsonError "js-message" err ] )

        _ ->
            ( model, Toasts.create Toast "warning" (Ports.unhandledJsMsgError msg) )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.onJsMessage Nothing JsMessage ]
            ++ Dropdown.subs model DropdownToggle (Noop "dropdown already opened")
        )



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = title, body = model |> viewNewProject req.url shared }
