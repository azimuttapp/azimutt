module Pages.Projects.New exposing (Model, Msg, page)

import Components.Molecules.Dropdown as Dropdown
import Conf exposing (SampleSchema)
import DataSources.DatabaseSchemaParser.DatabaseAdapter as DatabaseAdapter
import Dict
import Gen.Params.Projects.New exposing (Params)
import Gen.Route as Route
import Libs.Bool as B
import Libs.Http as Http
import Libs.Json.Decode as Decode
import Libs.Maybe as Maybe
import Libs.Result as Result
import Libs.String as String
import Libs.Task as T
import Models.Project as Project
import Models.Project.ProjectId as ProjectId
import Models.Project.ProjectStorage as ProjectStorage
import Models.Project.SourceId as SourceId
import Page
import PagesComponents.Projects.New.Models as Models exposing (Msg(..), Tab(..))
import PagesComponents.Projects.New.View exposing (viewNewProject)
import Ports exposing (JsMsg(..))
import Random
import Request
import Services.Backend as Backend exposing (BackendUrl)
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapDatabaseSourceM, mapJsonSourceM, mapJsonSourceMCmd, mapOpenedDialogs, mapProjectImportM, mapProjectImportMCmd, mapSampleSelectionM, mapSampleSelectionMCmd, mapSqlSourceM, mapSqlSourceMCmd, mapToastsCmd, setConfirm, setSeed, setStatus, setUrl)
import Services.ProjectImport as ProjectImport
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Shared
import Time
import Track
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init req shared.now
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


init : Request.With Params -> Time.Posix -> ( Model, Cmd Msg )
init req now =
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
                        Just "sql" ->
                            TabSql

                        Just "database" ->
                            TabDatabase

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
                            TabSql
                    )
    in
    ( { seed = Random.initialSeed (now |> Time.posixToMillis)
      , selectedMenu = "New project"
      , mobileMenuOpen = False
      , openedCollapse = ""
      , projects = []
      , selectedTab = TabSamples
      , sqlSource = Nothing
      , databaseSource = Nothing
      , jsonSource = Nothing
      , projectImport = Nothing
      , sampleSelection = Nothing
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
            ++ (sample |> Maybe.mapOrElse (\s -> [ T.send (SampleSelectMsg (ProjectImport.SelectRemoteFile s.url (Just s.key))) ]) [])
        )
    )


initTab : Tab -> Model -> Model
initTab tab model =
    let
        clean : Model
        clean =
            { model | selectedTab = tab, sqlSource = Nothing, databaseSource = Nothing, jsonSource = Nothing, projectImport = Nothing, sampleSelection = Nothing }
    in
    case tab of
        TabSql ->
            { clean | sqlSource = Just (SqlSource.init Conf.schema.default Nothing (\_ -> Noop "select-tab-sql-source")) }

        TabDatabase ->
            { clean | databaseSource = Just (DatabaseSource.init Nothing) }

        TabJson ->
            { clean | jsonSource = Just (JsonSource.init Nothing (\_ -> Noop "select-tab-json-source")) }

        TabProject ->
            { clean | projectImport = Just ProjectImport.init }

        TabSamples ->
            { clean | sampleSelection = Just ProjectImport.init }



-- UPDATE


update : Request.With Params -> Time.Posix -> BackendUrl -> Msg -> Model -> ( Model, Cmd Msg )
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

        SqlSourceMsg message ->
            model
                |> mapSqlSourceMCmd (SqlSource.update SqlSourceMsg message)
                |> (\( m, cmd ) ->
                        if message == SqlSource.BuildSource then
                            ( m, Cmd.batch [ cmd, Ports.confetti "create-project-btn" ] )

                        else
                            ( m, cmd )
                   )

        SqlSourceDrop ->
            ( model |> mapSqlSourceM (\_ -> SqlSource.init Conf.schema.default Nothing (\_ -> Noop "drop-sql-source")), Cmd.none )

        DatabaseSourceMsg (DatabaseSource.UpdateUrl url) ->
            ( model |> mapDatabaseSourceM (setUrl url), Cmd.none )

        DatabaseSourceMsg (DatabaseSource.FetchSchema url) ->
            ( model |> mapDatabaseSourceM (setStatus (DatabaseSource.Fetching url))
            , Backend.getDatabaseSchema backendUrl url (DatabaseSource.GotSchema url >> DatabaseSourceMsg)
            )

        DatabaseSourceMsg (DatabaseSource.GotSchema url result) ->
            ( model, Random.generate (DatabaseSource.GotSchemaWithId url result >> DatabaseSourceMsg) SourceId.generator )

        DatabaseSourceMsg (DatabaseSource.GotSchemaWithId url result sourceId) ->
            ( model
                |> mapDatabaseSourceM
                    (setStatus
                        (result
                            |> Result.fold
                                (Http.errorToString >> DatabaseSource.Error)
                                (DatabaseAdapter.buildDatabaseSource now sourceId url >> DatabaseSource.Success)
                        )
                    )
            , Cmd.none
            )

        DatabaseSourceMsg DatabaseSource.DropSchema ->
            ( model |> mapDatabaseSourceM (setStatus DatabaseSource.Pending), Cmd.none )

        DatabaseSourceMsg (DatabaseSource.CreateProject source) ->
            ( model, T.send (CreateProjectFromSource source) )

        JsonSourceMsg message ->
            model
                |> mapJsonSourceMCmd (JsonSource.update JsonSourceMsg message)
                |> (\( m, cmd ) ->
                        if message == JsonSource.BuildSource then
                            ( m, Cmd.batch [ cmd, Ports.confetti "create-project-btn" ] )

                        else
                            ( m, cmd )
                   )

        JsonSourceDrop ->
            ( model |> mapJsonSourceM (\_ -> JsonSource.init Nothing (\_ -> Noop "drop-json-source")), Cmd.none )

        ProjectImportMsg message ->
            model
                |> mapProjectImportMCmd (ProjectImport.update message)
                |> (\( m, cmd ) ->
                        case message of
                            ProjectImport.FileLoaded _ ->
                                ( m, Cmd.batch [ cmd, Ports.confetti "import-project-btn" ] )

                            _ ->
                                ( m, cmd )
                   )

        ProjectImportDrop ->
            ( model |> mapProjectImportM (\_ -> ProjectImport.init), Cmd.none )

        SampleSelectMsg message ->
            model
                |> mapSampleSelectionMCmd (ProjectImport.update message)
                |> (\( m, cmd ) ->
                        case message of
                            ProjectImport.FileLoaded _ ->
                                ( m, Cmd.batch [ cmd, Ports.confetti "sample-project-btn" ] )

                            _ ->
                                ( m, cmd )
                   )

        SampleSelectDrop ->
            ( model |> mapSampleSelectionM (\_ -> ProjectImport.init), Cmd.none )

        CreateProjectFromSource source ->
            model.seed
                |> Random.step ProjectId.generator
                |> Tuple.mapFirst (\projectId -> Project.create projectId (String.unique (model.projects |> List.map .name) source.name) source)
                |> (\( project, seed ) -> ( model |> setSeed seed, Cmd.batch [ Ports.createProject project, Ports.track (Track.createProject project), Request.pushRoute (Route.Projects__Id_ { id = project.id }) req ] ))

        CreateProject project ->
            ( model, Cmd.batch [ Ports.createProject project, Ports.track (Track.importProject project), Request.pushRoute (Route.Projects__Id_ { id = project.id }) req ] )

        CreateNewProject project ->
            let
                ( projectId, seed ) =
                    model.seed |> Random.step ProjectId.generator
            in
            ( model |> setSeed seed, T.send (CreateProject (project |> Project.duplicate (model.projects |> List.map .name) projectId)) )

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
            let
                ( sourceId, seed ) =
                    model.seed |> Random.step SourceId.generator

                updated : Model
                updated =
                    model |> setSeed seed
            in
            if kind == ProjectImport.kind then
                ( updated, T.send (ProjectImport.gotLocalFile content |> ProjectImportMsg) )

            else if kind == SqlSource.kind then
                ( updated, T.send (SqlSource.gotLocalFile now sourceId file content |> SqlSourceMsg) )

            else if kind == JsonSource.kind then
                ( updated, T.send (JsonSource.gotLocalFile now sourceId file content |> JsonSourceMsg) )

            else
                ( model, Toasts.error Toast ("Unhandled local file for " ++ kind ++ " source") )

        GotRemoteFile kind url content sample ->
            let
                ( sourceId, seed ) =
                    model.seed |> Random.step SourceId.generator

                updated : Model
                updated =
                    model |> setSeed seed
            in
            if kind == ProjectImport.kind then
                if sample == Nothing then
                    ( updated, T.send (ProjectImport.gotRemoteFile content |> ProjectImportMsg) )

                else
                    ( updated, T.send (ProjectImport.gotRemoteFile content |> SampleSelectMsg) )

            else if kind == SqlSource.kind then
                ( updated, T.send (SqlSource.gotRemoteFile now sourceId url content sample |> SqlSourceMsg) )

            else if kind == JsonSource.kind then
                ( updated, T.send (JsonSource.gotRemoteFile now sourceId url content sample |> JsonSourceMsg) )

            else
                ( model, Toasts.error Toast ("Unhandled remote file for " ++ kind ++ " source") )

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
