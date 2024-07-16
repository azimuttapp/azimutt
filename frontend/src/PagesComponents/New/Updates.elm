module PagesComponents.New.Updates exposing (update)

import Components.Molecules.Dropdown as Dropdown
import Conf
import Dict
import Gen.Route as Route
import Json.Decode as Decode
import Json.Encode as Encode
import Libs.Bool as B
import Libs.List as List
import Libs.Result as Result
import Libs.Task as T
import Models.OrganizationId as OrganizationId exposing (OrganizationId)
import Models.Project as Project
import Models.Project.ProjectId as ProjectId
import Models.Project.Source as Source
import Models.Project.SourceId as SourceId
import Models.ProjectInfo exposing (ProjectInfo)
import PagesComponents.New.Models exposing (Model, Msg(..), Tab(..))
import PagesComponents.Organization_.Project_.Updates.Extra as Extra
import Ports exposing (JsMsg(..))
import Random
import Request
import Services.Backend as Backend
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapDatabaseSourceMT, mapJsonSourceMT, mapOpenedDialogs, mapPrismaSourceMT, mapProjectSourceMTW, mapSampleSourceMTW, mapSqlSourceMT, mapToastsT, setConfirm)
import Services.PrismaSource as PrismaSource
import Services.ProjectSource as ProjectSource
import Services.SampleSource as SampleSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Time
import Track


update : Request.With params -> Time.Posix -> List ProjectInfo -> Maybe OrganizationId -> Msg -> Model -> ( Model, Cmd Msg )
update req now projects urlOrganization msg model =
    case msg of
        SelectMenu menu ->
            ( { model | selectedMenu = menu }, Cmd.none )

        ToggleCollapse id ->
            ( { model | openedCollapse = B.cond (model.openedCollapse == id) "" id }, Cmd.none )

        GotSamples res ->
            res
                |> Result.fold (\err -> ( model, "Error on samples: " ++ Backend.errorToString err |> Toasts.warning |> Toast |> T.send ))
                    (\samples ->
                        ( { model | samples = samples }
                        , req.query
                            |> Dict.get "sample"
                            |> Maybe.andThen (\value -> samples |> List.find (\s -> s.slug == value))
                            |> Maybe.map (SampleSource.GetSample >> SampleSourceMsg >> T.send)
                            |> Maybe.withDefault Cmd.none
                        )
                    )

        InitTab tab ->
            ( let
                clean : Model
                clean =
                    { model | selectedTab = tab, databaseSource = Nothing, sqlSource = Nothing, jsonSource = Nothing, projectSource = Nothing, sampleSource = Nothing }
              in
              case tab of
                TabDatabase ->
                    { clean | databaseSource = Just (DatabaseSource.init Nothing (\_ -> Noop "select-tab-database-source")) }

                TabSql ->
                    { clean | sqlSource = Just (SqlSource.init Nothing (\_ -> Noop "select-tab-sql-source")) }

                TabPrisma ->
                    { clean | prismaSource = Just (PrismaSource.init Nothing (\_ -> Noop "select-tab-prisma-source")) }

                TabJson ->
                    { clean | jsonSource = Just (JsonSource.init Nothing (\_ -> Noop "select-tab-json-source")) }

                TabEmptyProject ->
                    clean

                TabProject ->
                    { clean | projectSource = Just ProjectSource.init }

                TabSamples ->
                    { clean | sampleSource = Just SampleSource.init }
            , Cmd.none
            )

        DatabaseSourceMsg message ->
            (model |> mapDatabaseSourceMT (DatabaseSource.update DatabaseSourceMsg now Nothing message) |> Extra.unpackTM)
                |> Tuple.mapSecond
                    (\cmd ->
                        case message of
                            DatabaseSource.BuildSource _ ->
                                Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]

                            _ ->
                                cmd
                    )

        SqlSourceMsg message ->
            (model |> mapSqlSourceMT (SqlSource.update SqlSourceMsg now Nothing message) |> Extra.unpackTM)
                |> Tuple.mapSecond (\cmd -> B.cond (message == SqlSource.BuildSource) (Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]) cmd)

        PrismaSourceMsg message ->
            (model |> mapPrismaSourceMT (PrismaSource.update PrismaSourceMsg now Nothing message) |> Extra.unpackTM)
                |> Tuple.mapSecond (\cmd -> B.cond (message == PrismaSource.BuildSource) (Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]) cmd)

        JsonSourceMsg message ->
            (model |> mapJsonSourceMT (JsonSource.update JsonSourceMsg now Nothing message) |> Extra.unpackTM)
                |> Tuple.mapSecond (\cmd -> B.cond (message == JsonSource.BuildSource) (Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]) cmd)

        ProjectSourceMsg message ->
            (model |> mapProjectSourceMTW (ProjectSource.update ProjectSourceMsg message) Cmd.none)
                |> Tuple.mapSecond (\cmd -> B.cond (message == ProjectSource.BuildProject) (Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]) cmd)

        SampleSourceMsg message ->
            (model |> mapSampleSourceMTW (SampleSource.update SampleSourceMsg message) Cmd.none)
                |> Tuple.mapSecond (\cmd -> B.cond (message == SampleSource.BuildProject) (Cmd.batch [ cmd, Ports.confetti "create-project-btn" ]) cmd)

        CreateProjectTmp project ->
            ( model, Cmd.batch [ Ports.createProjectTmp project, Track.projectDraftCreated project ] )

        CreateEmptyProject name ->
            ( model, SourceId.generator |> Random.generate (Source.aml Conf.constants.virtualRelationSourceName now >> Project.create projects name >> CreateProjectTmp) )

        DropdownToggle id ->
            ( model |> Dropdown.update id, Cmd.none )

        Toast message ->
            model |> mapToastsT (Toasts.update Toast message) |> Extra.unpackT

        ConfirmOpen confirm ->
            ( model |> setConfirm (Just { id = Conf.ids.confirmDialog, content = confirm }), ModalOpen Conf.ids.confirmDialog |> T.sendAfter 1 )

        ConfirmAnswer answer cmd ->
            ( model |> setConfirm Nothing, B.cond answer cmd Cmd.none )

        ModalOpen id ->
            ( model |> mapOpenedDialogs (\dialogs -> id :: dialogs), Ports.autofocusWithin id )

        ModalClose message ->
            ( model |> mapOpenedDialogs (List.drop 1), message |> T.sendAfter Conf.ui.closeDuration )

        JsMessage message ->
            model |> handleJsMessage req urlOrganization message

        Noop _ ->
            ( model, Cmd.none )


handleJsMessage : Request.With params -> Maybe OrganizationId -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage req urlOrganization msg model =
    case msg of
        GotLocalFile kind file content ->
            if kind == ProjectSource.kind then
                ( model, content |> ProjectSource.GotFile |> ProjectSourceMsg |> T.send )

            else if kind == SqlSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> SqlSource.GotLocalFile sourceId file content |> SqlSourceMsg) )

            else if kind == PrismaSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> PrismaSource.GotLocalFile sourceId file content |> PrismaSourceMsg) )

            else if kind == JsonSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> JsonSource.GotLocalFile sourceId file content |> JsonSourceMsg) )

            else
                ( model, "Unhandled local file kind '" ++ kind ++ "'" |> Toasts.error |> Toast |> T.send )

        GotProject _ project ->
            if model.sampleSource == Nothing || (model.sampleSource |> Maybe.andThen .parsedProject) /= Nothing then
                ( model, Request.pushRoute (Route.Organization___Project_ { organization = urlOrganization |> Maybe.withDefault OrganizationId.zero, project = ProjectId.zero }) req )

            else
                ( model, project |> SampleSource.GotProject |> SampleSourceMsg |> T.send )

        GotDatabaseSchema schema ->
            ( model, Ok schema |> DatabaseSource.GotSchema |> DatabaseSourceMsg |> T.send )

        GotDatabaseSchemaError error ->
            ( model, Err error |> DatabaseSource.GotSchema |> DatabaseSourceMsg |> T.send )

        GotPrismaSchema schema ->
            ( model, Ok schema |> PrismaSource.GotSchema |> PrismaSourceMsg |> T.send )

        GotPrismaSchemaError error ->
            ( model, Err error |> PrismaSource.GotSchema |> PrismaSourceMsg |> T.send )

        GotToast level message ->
            ( model, message |> Toasts.create level |> Toast |> T.send )

        Error json err ->
            ( model, Cmd.batch [ "Unable to decode JavaScript message: " ++ Decode.errorToString err ++ " in " ++ Encode.encode 0 json |> Toasts.error |> Toast |> T.send, Track.jsonError "js_message" err ] )

        GotSizes _ ->
            ( model, Cmd.none )

        _ ->
            ( model, Ports.unhandledJsMsgError msg |> Toasts.create "warning" |> Toast |> T.send )
