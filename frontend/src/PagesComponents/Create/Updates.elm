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
import Models.Project.ProjectStorage as ProjectStorage
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.ProjectInfo exposing (ProjectInfo)
import PagesComponents.Create.Models exposing (Model, Msg(..))
import Ports exposing (JsMsg(..))
import Random
import Request
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapDatabaseSourceMCmd, mapJsonSourceMCmd, mapSqlSourceMCmd, mapToastsCmd)
import Services.Sort as Sort
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Time
import Track


update : Request.With params -> Time.Posix -> Maybe OrganizationId -> Msg -> Model -> ( Model, Cmd Msg )
update req now urlOrganization msg model =
    case msg of
        InitProject ->
            let
                name : ProjectName
                name =
                    req.query |> Dict.getOrElse "name" Conf.constants.newProjectName
            in
            ( (req.query |> Dict.get "database" |> Maybe.map (\_ -> { model | databaseSource = Just (DatabaseSource.init Nothing (createProject model.projects name)) }))
                |> Maybe.orElse (req.query |> Dict.get "sql" |> Maybe.map (\_ -> { model | sqlSource = Just (SqlSource.init Nothing (Tuple.second >> createProject model.projects name)) }))
                |> Maybe.orElse (req.query |> Dict.get "json" |> Maybe.map (\_ -> { model | jsonSource = Just (JsonSource.init Nothing (createProject model.projects name)) }))
                |> Maybe.withDefault model
            , (req.query |> Dict.get "database" |> Maybe.map (DatabaseSource.GetSchema >> DatabaseSourceMsg >> T.send))
                |> Maybe.orElse (req.query |> Dict.get "sql" |> Maybe.map (SqlSource.GetRemoteFile >> SqlSourceMsg >> T.send))
                |> Maybe.orElse (req.query |> Dict.get "json" |> Maybe.map (JsonSource.GetRemoteFile >> JsonSourceMsg >> T.send))
                |> Maybe.withDefault (AmlSourceMsg name |> T.send)
            )

        DatabaseSourceMsg message ->
            model |> mapDatabaseSourceMCmd (DatabaseSource.update DatabaseSourceMsg now message)

        JsonSourceMsg message ->
            model |> mapJsonSourceMCmd (JsonSource.update JsonSourceMsg now message)

        SqlSourceMsg message ->
            model |> mapSqlSourceMCmd (SqlSource.update SqlSourceMsg now message)

        AmlSourceMsg name ->
            ( model, SourceId.generator |> Random.generate (Source.aml Conf.constants.virtualRelationSourceName now >> Project.create model.projects name >> CreateProjectTmp) )

        CreateProjectTmp project ->
            ( model
            , Cmd.batch
                (Maybe.zip urlOrganization (req.query |> Dict.get "heroku")
                    |> Maybe.map (\( organizationId, heroku ) -> [ Ports.createProject organizationId ProjectStorage.Remote (Just heroku) project, Ports.track (Track.createProject project) ])
                    |> Maybe.withDefault [ Ports.createProjectTmp project, Ports.track (Track.initProject project) ]
                )
            )

        Toast message ->
            model |> mapToastsCmd (Toasts.update Toast message)

        JsMessage message ->
            model |> handleJsMessage req urlOrganization message


createProject : List ProjectInfo -> ProjectName -> Result String Source -> Msg
createProject projects name =
    Result.fold (Toasts.error >> Toast) (Project.create projects name >> CreateProjectTmp)


handleJsMessage : Request.With params -> Maybe OrganizationId -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage req urlOrganization msg model =
    case msg of
        GotLegacyProjects ( _, projects ) ->
            ( { model | projects = Sort.lastUpdatedFirst projects }, T.send InitProject )

        GotProject project ->
            ( model
            , Request.pushRoute
                (Route.Organization___Project_
                    { organization = project |> Maybe.andThen Result.toMaybe |> Maybe.andThen .organization |> Maybe.map .id |> Maybe.orElse urlOrganization |> Maybe.withDefault OrganizationId.zero
                    , project = project |> Maybe.andThen Result.toMaybe |> Maybe.mapOrElse .id ProjectId.zero
                    }
                )
                req
            )

        GotToast level message ->
            ( model, message |> Toasts.create level |> Toast |> T.send )

        _ ->
            ( model, Ports.unhandledJsMsgError msg |> Toasts.create "warning" |> Toast |> T.send )
