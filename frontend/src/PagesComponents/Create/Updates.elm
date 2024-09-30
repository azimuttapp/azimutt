module PagesComponents.Create.Updates exposing (update)

import Conf
import DataSources.JsonMiner.JsonAdapter as JsonAdapter
import Dict exposing (Dict)
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
import PagesComponents.Organization_.Project_.Updates.Extra as Extra
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


update : Request.With params -> Dict String String -> Time.Posix -> List ProjectInfo -> Bool -> Maybe OrganizationId -> Msg -> Model -> ( Model, Cmd Msg )
update req params now projects projectsLoaded urlOrganization msg model =
    case msg of
        InitProject ->
            if projectsLoaded then
                let
                    name : ProjectName
                    name =
                        params |> Dict.getOrElse "name" Conf.constants.newProjectName

                    storage : Maybe ProjectStorage
                    storage =
                        params |> Dict.get "storage" |> Maybe.andThen ProjectStorage.fromString
                in
                ( (params |> Dict.get "database" |> Maybe.map (\_ -> { model | databaseSource = Just (DatabaseSource.init Nothing (createProject urlOrganization projects storage name)) }))
                    |> Maybe.orElse (params |> Dict.get "sql" |> Maybe.map (\_ -> { model | sqlSource = Just (SqlSource.init Nothing (Tuple.second >> createProject urlOrganization projects storage name)) }))
                    |> Maybe.orElse (params |> Dict.get "prisma" |> Maybe.map (\_ -> { model | prismaSource = Just (PrismaSource.init Nothing (createProject urlOrganization projects storage name)) }))
                    |> Maybe.orElse (params |> Dict.get "json" |> Maybe.map (\_ -> { model | jsonSource = Just (JsonSource.init Nothing (createProject urlOrganization projects storage name)) }))
                    |> Maybe.orElse (params |> Dict.get "aml" |> Maybe.map (\aml -> { model | amlSource = Just { content = aml, callback = createProject urlOrganization projects storage name } }))
                    |> Maybe.withDefault model
                , (params |> Dict.get "database" |> Maybe.map (DatabaseSource.GetSchema >> DatabaseSourceMsg >> T.send))
                    |> Maybe.orElse (params |> Dict.get "sql" |> Maybe.map (SqlSource.GetRemoteFile >> SqlSourceMsg >> T.send))
                    |> Maybe.orElse (params |> Dict.get "prisma" |> Maybe.map (PrismaSource.GetRemoteFile >> PrismaSourceMsg >> T.send))
                    |> Maybe.orElse (params |> Dict.get "json" |> Maybe.map (JsonSource.GetRemoteFile >> JsonSourceMsg >> T.send))
                    |> Maybe.orElse (params |> Dict.get "aml" |> Maybe.map (AmlSourceMsg >> T.send))
                    |> Maybe.withDefault (NoSourceMsg storage name |> T.send)
                )

            else
                ( model, InitProject |> T.sendAfter 500 )

        DatabaseSourceMsg message ->
            model |> mapDatabaseSourceMT (DatabaseSource.update DatabaseSourceMsg now Nothing message) |> Extra.unpackTM

        SqlSourceMsg message ->
            model |> mapSqlSourceMT (SqlSource.update SqlSourceMsg now Nothing message) |> Extra.unpackTM

        PrismaSourceMsg message ->
            model |> mapPrismaSourceMT (PrismaSource.update PrismaSourceMsg now Nothing message) |> Extra.unpackTM

        JsonSourceMsg message ->
            model |> mapJsonSourceMT (JsonSource.update JsonSourceMsg now Nothing message) |> Extra.unpackTM

        AmlSourceMsg content ->
            ( model, SourceId.generator |> Random.generate (\sourceId -> Ports.getAmlSchema sourceId content |> Send) )

        NoSourceMsg storage name ->
            ( model, SourceId.generator |> Random.generate (Source.empty Conf.constants.defaultSourceName now >> Project.create urlOrganization projects name >> CreateProjectTmp storage) )

        CreateProjectTmp storage project ->
            ( model
            , Cmd.batch
                (Maybe.zip urlOrganization storage
                    |> Maybe.map (\( organizationId, s ) -> [ Ports.createProject organizationId s project ])
                    |> Maybe.withDefault [ Ports.createProjectTmp project, Track.projectDraftCreated project ]
                )
            )

        Toast message ->
            model |> mapToastsT (Toasts.update Toast message) |> Extra.unpackT

        Send cmd ->
            ( model, cmd )

        Noop _ ->
            ( model, Cmd.none )

        JsMessage message ->
            model |> handleJsMessage req urlOrganization now message


createProject : Maybe OrganizationId -> List ProjectInfo -> Maybe ProjectStorage -> ProjectName -> Result String Source -> Msg
createProject urlOrganization projects storage name =
    Result.fold (Toasts.error >> Toast) (Project.create urlOrganization projects name >> CreateProjectTmp storage)


handleJsMessage : Request.With params -> Maybe OrganizationId -> Time.Posix -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage req urlOrganization now msg model =
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
            ( model, Cmd.batch [ Err error |> DatabaseSource.GotSchema |> DatabaseSourceMsg |> T.send, error |> Toasts.error |> Toast |> T.send ] )

        GotPrismaSchema schema ->
            ( model, Ok schema |> PrismaSource.GotSchema |> PrismaSourceMsg |> T.send )

        GotPrismaSchemaError error ->
            ( model, Cmd.batch [ Err error |> PrismaSource.GotSchema |> PrismaSourceMsg |> T.send, error |> Toasts.error |> Toast |> T.send ] )

        GotAmlSchema sourceId length jsonSchema errors ->
            model.amlSource
                |> Maybe.map
                    (\amlSource ->
                        jsonSchema
                            |> Maybe.filter (\_ -> length == String.length amlSource.content)
                            |> Maybe.map JsonAdapter.buildSchema
                            |> Maybe.map (\schema -> Source.aml sourceId Conf.constants.defaultSourceName amlSource.content schema now |> Ok)
                            |> Maybe.withDefault ("Errors: " ++ (errors |> List.map (\e -> e.message ++ " at line " ++ String.fromInt e.position.start.line) |> String.join ", ") |> Err)
                            |> (\res -> ( model, amlSource.callback res |> T.send ))
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        GotToast level message ->
            ( model, message |> Toasts.create level |> Toast |> T.send )

        _ ->
            ( model, Ports.unhandledJsMsgError msg |> Toasts.create "warning" |> Toast |> T.send )
