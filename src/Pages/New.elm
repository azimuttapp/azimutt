module Pages.New exposing (Model, Msg, page)

import Components.Molecules.Dropdown as Dropdown
import Conf
import Dict
import Gen.Params.Projects.New exposing (Params)
import Gen.Route as Route
import Json.Decode as Decode
import Json.Encode as Encode
import Libs.Bool as B
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project as Project
import Models.Project.Source as Source
import Models.Project.SourceId as SourceId
import Models.SourceInfo as SourceInfo
import Page
import PagesComponents.New.Models as Models exposing (Msg(..), Tab(..))
import PagesComponents.New.View exposing (viewNewProject)
import Ports exposing (JsMsg(..))
import Random
import Request
import Services.DatabaseSource as DatabaseSource
import Services.ImportProject as ImportProject
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapDatabaseSourceMCmd, mapImportProjectMCmd, mapJsonSourceMCmd, mapOpenedDialogs, mapSampleProjectMCmd, mapSqlSourceMCmd, mapToastsCmd, setConfirm)
import Services.Sort as Sort
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
        , update = update req shared.now
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
    ( { selectedMenu = "New project"
      , mobileMenuOpen = False
      , openedCollapse = ""
      , projects = []
      , selectedTab = TabDatabase
      , databaseSource = Nothing
      , sqlSource = Nothing
      , jsonSource = Nothing
      , importProject = Nothing
      , sampleProject = Nothing
      , openedDropdown = ""
      , toasts = Toasts.init
      , confirm = Nothing
      , openedDialogs = []
      }
    , Cmd.batch
        ([ Ports.setMeta
            { title = Just title
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = Route.New, query = Dict.empty }
            , html = Just "h-full bg-gray-100"
            , body = Just "h-full"
            }
         , Ports.trackPage "new-project"
         , Ports.listProjects
         ]
            ++ ((req.query |> Dict.get "database" |> Maybe.map (\value -> [ T.send (InitTab TabDatabase), T.sendAfter 1 (DatabaseSourceMsg (DatabaseSource.GetSchema value)) ]))
                    |> Maybe.orElse (req.query |> Dict.get "sql" |> Maybe.map (\value -> [ T.send (InitTab TabSql), T.sendAfter 1 (SqlSourceMsg (SqlSource.GetRemoteFile value)) ]))
                    |> Maybe.orElse (req.query |> Dict.get "json" |> Maybe.map (\value -> [ T.send (InitTab TabJson), T.sendAfter 1 (JsonSourceMsg (JsonSource.GetRemoteFile value)) ]))
                    |> Maybe.orElse (req.query |> Dict.get "empty" |> Maybe.map (\_ -> [ T.send (InitTab TabEmptyProject) ]))
                    |> Maybe.orElse (req.query |> Dict.get "project" |> Maybe.map (\value -> [ T.send (InitTab TabProject), T.sendAfter 1 (ImportProjectMsg (ImportProject.GetRemoteFile value Nothing)) ]))
                    |> Maybe.orElse (req.query |> Dict.get "sample" |> Maybe.map (\value -> T.send (InitTab TabSamples) :: (Conf.schemaSamples |> Dict.get value |> Maybe.mapOrElse (\s -> [ T.sendAfter 1 (SampleProjectMsg (ImportProject.GetRemoteFile s.url (Just s.key))) ]) [])))
                    |> Maybe.withDefault [ T.send (InitTab TabDatabase) ]
               )
        )
    )



-- UPDATE


update : Request.With Params -> Time.Posix -> Msg -> Model -> ( Model, Cmd Msg )
update req now msg model =
    case msg of
        SelectMenu menu ->
            ( { model | selectedMenu = menu }, Cmd.none )

        ToggleCollapse id ->
            ( { model | openedCollapse = B.cond (model.openedCollapse == id) "" id }, Cmd.none )

        InitTab tab ->
            ( let
                clean : Model
                clean =
                    { model | selectedTab = tab, databaseSource = Nothing, sqlSource = Nothing, jsonSource = Nothing, importProject = Nothing, sampleProject = Nothing }
              in
              case tab of
                TabDatabase ->
                    { clean | databaseSource = Just (DatabaseSource.init Nothing (\_ -> Noop "select-tab-database-source")) }

                TabSql ->
                    { clean | sqlSource = Just (SqlSource.init Nothing (\_ -> Noop "select-tab-sql-source")) }

                TabJson ->
                    { clean | jsonSource = Just (JsonSource.init Nothing (\_ -> Noop "select-tab-json-source")) }

                TabEmptyProject ->
                    clean

                TabProject ->
                    { clean | importProject = Just ImportProject.init }

                TabSamples ->
                    { clean | sampleProject = Just ImportProject.init }
            , Cmd.none
            )

        DatabaseSourceMsg message ->
            (model |> mapDatabaseSourceMCmd (DatabaseSource.update DatabaseSourceMsg now message))
                |> Tuple.mapSecond
                    (\cmd ->
                        case message of
                            DatabaseSource.BuildSource _ ->
                                Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]

                            _ ->
                                cmd
                    )

        SqlSourceMsg message ->
            (model |> mapSqlSourceMCmd (SqlSource.update SqlSourceMsg now message))
                |> Tuple.mapSecond (\cmd -> B.cond (message == SqlSource.BuildSource) (Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]) cmd)

        JsonSourceMsg message ->
            (model |> mapJsonSourceMCmd (JsonSource.update JsonSourceMsg now message))
                |> Tuple.mapSecond (\cmd -> B.cond (message == JsonSource.BuildSource) (Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]) cmd)

        ImportProjectMsg message ->
            (model |> mapImportProjectMCmd (ImportProject.update ImportProjectMsg message))
                |> Tuple.mapSecond (\cmd -> B.cond (message == ImportProject.BuildProject) (Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]) cmd)

        SampleProjectMsg message ->
            (model |> mapSampleProjectMCmd (ImportProject.update SampleProjectMsg message))
                |> Tuple.mapSecond (\cmd -> B.cond (message == ImportProject.BuildProject) (Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]) cmd)

        CreateProject project ->
            ( model, Cmd.batch [ Ports.createProjectTmp project, Ports.track (Track.initProject project), Request.pushRoute (Route.Organization___Project_ { organization = Conf.constants.tmpOrg, project = project.id }) req ] )

        CreateEmptyProject name ->
            ( model, SourceId.generator |> Random.generate (Source.aml Conf.constants.virtualRelationSourceName now >> Project.create model.projects name >> CreateProject) )

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
            ( { model | projects = Sort.lastUpdatedFirst projects }, Cmd.none )

        GotLocalFile kind file content ->
            if kind == ImportProject.kind then
                ( model, T.send (content |> ImportProject.GotFile |> ImportProjectMsg) )

            else if kind == SqlSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> SqlSource.GotFile (SourceInfo.sqlLocal now sourceId file) |> SqlSourceMsg) )

            else if kind == JsonSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> JsonSource.GotFile (SourceInfo.jsonLocal now sourceId file) |> JsonSourceMsg) )

            else
                ( model, "Unhandled local file kind '" ++ kind ++ "'" |> Toasts.error |> Toast |> T.send )

        GotToast level message ->
            ( model, message |> Toasts.create level |> Toast |> T.send )

        Error json err ->
            ( model, Cmd.batch [ "Unable to decode JavaScript message: " ++ Decode.errorToString err ++ " in " ++ Encode.encode 0 json |> Toasts.error |> Toast |> T.send, Ports.trackJsonError "js-message" err ] )

        _ ->
            ( model, Ports.unhandledJsMsgError msg |> Toasts.create "warning" |> Toast |> T.send )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch (Ports.onJsMessage JsMessage :: Dropdown.subs model DropdownToggle (Noop "dropdown already opened"))



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = title, body = model |> viewNewProject req.url shared }
