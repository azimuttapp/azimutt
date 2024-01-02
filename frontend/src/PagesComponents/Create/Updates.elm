module PagesComponents.Create.Updates exposing (update)

import Conf
import Dict
import Gen.Route as Route
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Result as Result
import Libs.Task as T
import Models.OrganizationId as OrganizationId exposing (OrganizationId)
import Models.Project as Project
import Models.Project.ProjectId as ProjectId
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.ProjectInfo exposing (ProjectInfo)
import PagesComponents.Create.Models exposing (Model, Msg(..))
import Ports exposing (JsMsg(..))
import Random
import Request
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapDatabaseSourceMT, mapJsonSourceMT, mapPrismaSourceMT, mapSqlSourceMT, mapToastsT)
import Services.PrismaSource as PrismaSource
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Time
import Track


update : Request.With params -> Time.Posix -> List ProjectInfo -> Bool -> Maybe OrganizationId -> Msg -> Model -> ( Model, Cmd Msg )
update req now projects projectsLoaded urlOrganization msg model =
    case msg of
        InitProject ->
            if projectsLoaded then
                let
                    name : ProjectName
                    name =
                        req.query |> Dict.getOrElse "name" Conf.constants.newProjectName

                    storage : Maybe ProjectStorage
                    storage =
                        req.query |> Dict.get "storage" |> Maybe.andThen ProjectStorage.fromString
                in
                ( (req.query |> Dict.get "database" |> Maybe.map (\_ -> { model | databaseSource = Just (DatabaseSource.init Nothing (createProject projects storage name)) }))
                    |> Maybe.orElse (req.query |> Dict.get "sql" |> Maybe.map (\_ -> { model | sqlSource = Just (SqlSource.init Nothing (Tuple.second >> createProject projects storage name)) }))
                    |> Maybe.orElse (req.query |> Dict.get "prisma" |> Maybe.map (\_ -> { model | prismaSource = Just (PrismaSource.init Nothing (createProject projects storage name)) }))
                    |> Maybe.orElse (req.query |> Dict.get "json" |> Maybe.map (\_ -> { model | jsonSource = Just (JsonSource.init Nothing (createProject projects storage name)) }))
                    |> Maybe.withDefault model
                , (req.query |> Dict.get "database" |> Maybe.map (DatabaseSource.GetSchema >> DatabaseSourceMsg >> T.send))
                    |> Maybe.orElse (req.query |> Dict.get "sql" |> Maybe.map (SqlSource.GetRemoteFile >> SqlSourceMsg >> T.send))
                    |> Maybe.orElse (req.query |> Dict.get "prisma" |> Maybe.map (PrismaSource.GetRemoteFile >> PrismaSourceMsg >> T.send))
                    |> Maybe.orElse (req.query |> Dict.get "json" |> Maybe.map (JsonSource.GetRemoteFile >> JsonSourceMsg >> T.send))
                    |> Maybe.withDefault (AmlSourceMsg storage name |> T.send)
                )

            else
                ( model, InitProject |> T.sendAfter 500 )

        DatabaseSourceMsg message ->
            model |> mapDatabaseSourceMT (DatabaseSource.update DatabaseSourceMsg now Nothing message) |> Tuple.mapSecond (Maybe.mapOrElse Tuple.first Cmd.none)

        SqlSourceMsg message ->
            model |> mapSqlSourceMT (SqlSource.update SqlSourceMsg now Nothing message) |> Tuple.mapSecond (Maybe.mapOrElse Tuple.first Cmd.none)

        PrismaSourceMsg message ->
            model |> mapPrismaSourceMT (PrismaSource.update PrismaSourceMsg now Nothing message) |> Tuple.mapSecond (Maybe.mapOrElse Tuple.first Cmd.none)

        JsonSourceMsg message ->
            model |> mapJsonSourceMT (JsonSource.update JsonSourceMsg now Nothing message) |> Tuple.mapSecond (Maybe.mapOrElse Tuple.first Cmd.none)

        AmlSourceMsg storage name ->
            ( model, SourceId.generator |> Random.generate (Source.aml Conf.constants.virtualRelationSourceName now >> Project.create projects name >> CreateProjectTmp storage) )

        CreateProjectTmp storage project ->
            ( model
            , Cmd.batch
                (Maybe.zip urlOrganization storage
                    |> Maybe.map (\( organizationId, s ) -> [ Ports.createProject organizationId s project ])
                    |> Maybe.withDefault [ Ports.createProjectTmp project, Track.projectDraftCreated project ]
                )
            )

        Toast message ->
            model |> mapToastsT (Toasts.update Toast message) |> Tuple.mapSecond Tuple.first

        JsMessage message ->
            model |> handleJsMessage req urlOrganization message


createProject : List ProjectInfo -> Maybe ProjectStorage -> ProjectName -> Result String Source -> Msg
createProject projects storage name =
    Result.fold (Toasts.error >> Toast) (Project.create projects name >> CreateProjectTmp storage)


handleJsMessage : Request.With params -> Maybe OrganizationId -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage req urlOrganization msg model =
    case msg of
        GotProject _ project ->
            ( model
            , Request.pushRoute
                (Route.Organization___Project_
                    { organization = project |> Maybe.andThen Result.toMaybe |> Maybe.andThen .organization |> Maybe.map .id |> Maybe.orElse urlOrganization |> Maybe.withDefault OrganizationId.zero
                    , project = project |> Maybe.andThen Result.toMaybe |> Maybe.mapOrElse .id ProjectId.zero
                    }
                )
                req
            )

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

        _ ->
            ( model, Ports.unhandledJsMsgError msg |> Toasts.create "warning" |> Toast |> T.send )
