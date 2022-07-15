module PagesComponents.Projects.Id_.Updates.ProjectSettings exposing (Model, handleProjectSettings)

import Conf
import DataSources.DatabaseSchemaParser.DatabaseAdapter as DatabaseAdapter
import Libs.Bool as B
import Libs.Http as Http
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project.ProjectSettings as ProjectSettings
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectSettingsDialog, ProjectSettingsMsg(..), SourceUploadDialog)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import Ports
import Random
import Services.Backend as Backend exposing (BackendUrl)
import Services.DatabaseSource as DatabaseSource
import Services.Lenses exposing (mapCollapseTableColumns, mapColumnBasicTypes, mapDatabaseSource, mapEnabled, mapErdM, mapHiddenColumns, mapParsingCmd, mapProps, mapRelations, mapRemoveViews, mapRemovedSchemas, mapSourceUploadM, mapSourceUploadMCmd, setColumnOrder, setDefaultSchema, setList, setMax, setRelationStyle, setRemovedTables, setSeed, setSettings, setSourceUpload, setStatus, setUrl)
import Services.SqlSourceUpload as SqlSourceUpload
import Services.Toasts as Toasts
import Time
import Track


type alias Model x =
    { x
        | seed : Random.Seed
        , erd : Maybe Erd
        , settings : Maybe ProjectSettingsDialog
        , sourceUpload : Maybe SourceUploadDialog
    }


handleProjectSettings : Time.Posix -> BackendUrl -> ProjectSettingsMsg -> Model x -> ( Model x, Cmd Msg )
handleProjectSettings now backendUrl msg model =
    case msg of
        PSOpen ->
            ( model |> setSettings (Just { id = Conf.ids.settingsDialog }), Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.settingsDialog), Ports.track Track.openSettings ] )

        PSClose ->
            ( model |> setSettings Nothing, Cmd.none )

        PSSourceToggle source ->
            model
                |> mapErdM (Erd.mapSource source.id (mapEnabled not))
                |> (\updated ->
                        ( updated
                        , Cmd.batch
                            [ Ports.observeTablesSize (updated.erd |> getShownTables)
                            , Toasts.info Toast ("Source " ++ source.name ++ " set to " ++ B.cond source.enabled "hidden" "visible" ++ ".")
                            ]
                        )
                   )

        PSSourceDelete source ->
            ( model |> mapErdM (Erd.mapSources (List.filter (\s -> s.id /= source.id))), Toasts.info Toast ("Source " ++ source.name ++ " has been deleted from your project.") )

        PSSourceUploadOpen source ->
            ( model
                |> setSourceUpload
                    (Just
                        { id = Conf.ids.sourceUploadDialog
                        , parsing = SqlSourceUpload.init (model.erd |> Erd.defaultSchemaM) (model.erd |> Maybe.map (\p -> p.project.id)) source (\_ -> Noop "project-settings-source-parsed")
                        , databaseSource = DatabaseSource.init (source |> Maybe.map .id)
                        }
                    )
            , T.sendAfter 1 (ModalOpen Conf.ids.sourceUploadDialog)
            )

        PSSourceUploadClose ->
            ( model |> setSourceUpload Nothing, Cmd.none )

        PSSqlSourceMsg message ->
            model |> mapSourceUploadMCmd (mapParsingCmd (SqlSourceUpload.update message (PSSqlSourceMsg >> ProjectSettingsMsg)))

        PSDatabaseSourceMsg (DatabaseSource.UpdateUrl url) ->
            ( model |> mapSourceUploadM (mapDatabaseSource (setUrl url)), Cmd.none )

        PSDatabaseSourceMsg (DatabaseSource.FetchSchema url) ->
            ( model |> mapSourceUploadM (mapDatabaseSource (setStatus (DatabaseSource.Fetching url)))
            , Backend.getDatabaseSchema backendUrl url (DatabaseSource.GotSchema url >> PSDatabaseSourceMsg >> ProjectSettingsMsg)
            )

        PSDatabaseSourceMsg (DatabaseSource.GotSchema url result) ->
            case result of
                Ok schema ->
                    let
                        ( sourceId, seed ) =
                            model.sourceUpload |> Maybe.andThen (.databaseSource >> .source) |> Maybe.mapOrElse (\id -> ( id, model.seed )) (SourceId.random model.seed)

                        source : Source
                        source =
                            DatabaseAdapter.buildDatabaseSource now sourceId url schema
                    in
                    ( model |> setSeed seed |> mapSourceUploadM (mapDatabaseSource (setStatus (DatabaseSource.Success source))), Cmd.none )

                Err err ->
                    ( model |> mapSourceUploadM (mapDatabaseSource (setStatus (DatabaseSource.Error (Http.errorToString err)))), Cmd.none )

        PSDatabaseSourceMsg DatabaseSource.DropSchema ->
            ( model |> mapSourceUploadM (mapDatabaseSource (setStatus DatabaseSource.Pending)), Cmd.none )

        PSDatabaseSourceMsg (DatabaseSource.CreateProject source) ->
            ( model, T.send (PSSourceRefresh source |> ProjectSettingsMsg) )

        PSSourceRefresh source ->
            ( model |> mapErdM (Erd.mapSource source.id (Source.refreshWith source)), Cmd.batch [ T.send (ModalClose (ProjectSettingsMsg PSSourceUploadClose)), Ports.track (Track.refreshSource source) ] )

        PSSourceAdd source ->
            ( model |> mapErdM (Erd.mapSources (\sources -> sources ++ [ source ])), Cmd.batch [ T.send (ModalClose (ProjectSettingsMsg PSSourceUploadClose)), Ports.track (Track.addSource source) ] )

        PSDefaultSchemaUpdate value ->
            ( model |> mapErdM (Erd.mapSettings (setDefaultSchema value)), Cmd.none )

        PSSchemaToggle schema ->
            model |> mapErdM (Erd.mapSettings (mapRemovedSchemas (List.toggle schema))) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) ))

        PSRemoveViewsToggle ->
            model |> mapErdM (Erd.mapSettings (mapRemoveViews not)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) ))

        PSRemovedTablesUpdate values ->
            model |> mapErdM (Erd.mapSettings (setRemovedTables values >> ProjectSettings.fillFindPath)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) ))

        PSHiddenColumnsListUpdate values ->
            ( model |> mapErdM (Erd.mapSettings (mapHiddenColumns (setList values) >> ProjectSettings.fillFindPath)), Cmd.none )

        PSHiddenColumnsMaxUpdate value ->
            ( value |> String.toInt |> Maybe.mapOrElse (\max -> model |> mapErdM (Erd.mapSettings (mapHiddenColumns (setMax max) >> ProjectSettings.fillFindPath))) model, Cmd.none )

        PSHiddenColumnsPropsToggle ->
            ( model |> mapErdM (Erd.mapSettings (mapHiddenColumns (mapProps not))), Cmd.none )

        PSHiddenColumnsRelationsToggle ->
            ( model |> mapErdM (Erd.mapSettings (mapHiddenColumns (mapRelations not))), Cmd.none )

        PSColumnOrderUpdate order ->
            ( model |> mapErdM (\e -> e |> Erd.mapSettings (setColumnOrder order)), Cmd.none )

        PSRelationStyleUpdate style ->
            ( model |> mapErdM (\e -> e |> Erd.mapSettings (setRelationStyle style)), Cmd.none )

        PSColumnBasicTypesToggle ->
            ( model |> mapErdM (Erd.mapSettings (mapColumnBasicTypes not)), Cmd.none )

        PSCollapseTableOnShowToggle ->
            ( model |> mapErdM (Erd.mapSettings (mapCollapseTableColumns not)), Cmd.none )


getShownTables : Maybe Erd -> List TableId
getShownTables erd =
    erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables >> List.map .id) []
