module PagesComponents.Organization_.Project_.Updates.ProjectSettings exposing (Model, handleProjectSettings)

import Conf
import Libs.Bool as B
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Libs.Tuple as Tuple
import Models.Project.ProjectSettings as ProjectSettings
import Models.Project.Source as Source exposing (Source)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), ProjectSettingsDialog, ProjectSettingsMsg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setHDirty, setHDirtyCmd, setHLDirty, setHLDirtyCmd)
import Ports
import Services.Lenses exposing (mapCollapseTableColumns, mapColumnBasicTypes, mapEnabled, mapErdM, mapErdMT, mapErdMTM, mapHiddenColumns, mapNameT, mapProps, mapRelations, mapRemoveViews, mapRemovedSchemas, mapSettingsM, mapSourceUpdateT, setColumnOrder, setDefaultSchema, setList, setMax, setRelationStyle, setRemovedTables, setSettings)
import Services.Toasts as Toasts
import Time
import Track


type alias Model x =
    { x
        | conf : ErdConf
        , dirty : Bool
        , erd : Maybe Erd
        , settings : Maybe ProjectSettingsDialog
        , sourceUpdate : Maybe (SourceUpdateDialog.Model Msg)
    }


handleProjectSettings : Time.Posix -> ProjectSettingsMsg -> Model x -> ( Model x, Cmd Msg, List ( Msg, Msg ) )
handleProjectSettings now msg model =
    case msg of
        PSOpen ->
            ( model |> setSettings (Just { id = Conf.ids.settingsDialog, sourceNameEdit = Nothing }), ModalOpen Conf.ids.settingsDialog |> T.sendAfter 1, [] )

        PSClose ->
            ( model |> setSettings Nothing, Cmd.none, [] )

        PSSourceToggle source ->
            model
                |> mapErdM (Erd.mapSource source.id (mapEnabled not))
                |> (\newModel ->
                        ( newModel
                        , Cmd.batch
                            [ Ports.observeTablesSize (newModel.erd |> getShownTables)
                            , "'" ++ source.name ++ "' source set to " ++ B.cond source.enabled "hidden" "visible" ++ "." |> Toasts.info |> Toast |> T.send
                            ]
                        )
                   )
                |> setHDirtyCmd []

        PSSourceNameUpdate source name ->
            ( model |> mapSettingsM (\s -> { s | sourceNameEdit = Just ( source, name ) }), Cmd.none, [] )

        PSSourceNameUpdateDone source name ->
            model
                |> mapSettingsM (\s -> { s | sourceNameEdit = Nothing })
                |> mapErdMTM
                    (Erd.mapSourceT source
                        (mapNameT
                            (\old ->
                                ( name
                                , if old == name then
                                    []

                                  else
                                    [ ( PSSourceNameUpdateDone source old, PSSourceNameUpdateDone source name ) |> Tuple.map ProjectSettingsMsg ]
                                )
                            )
                        )
                    )
                |> setHLDirty

        PSSourceDelete sourceId ->
            model
                |> mapErdMT
                    (Erd.mapSourcesT
                        (\sources ->
                            case sources |> List.zipWithIndex |> List.partition (\( s, _ ) -> s.id == sourceId) of
                                ( ( deleted, index ) :: _, kept ) ->
                                    ( kept |> List.map Tuple.first
                                    , ( Cmd.batch [ "'" ++ deleted.name ++ "' source removed from project." |> Toasts.info |> Toast |> T.send, Track.sourceDeleted model.erd deleted ]
                                      , [ ( PSSourceUnDelete_ index deleted, msg ) |> Tuple.map ProjectSettingsMsg ]
                                      )
                                    )

                                _ ->
                                    ( sources, ( Cmd.none, [] ) )
                        )
                    )
                |> setHLDirtyCmd

        PSSourceUnDelete_ index source ->
            model
                |> mapErdM (Erd.mapSources (List.insertAt index source))
                |> (\newModel -> ( newModel, Ports.observeTablesSize (newModel.erd |> getShownTables) ) |> setHDirtyCmd [])

        PSSourceUpdate message ->
            model |> mapSourceUpdateT (SourceUpdateDialog.update (PSSourceUpdate >> ProjectSettingsMsg) ModalOpen Noop now (model.erd |> Maybe.map .project) message) |> Tuple.append []

        PSSourceSet source ->
            model
                |> mapErdMT
                    (Erd.mapSourcesT
                        (\sources ->
                            let
                                close : Cmd Msg
                                close =
                                    model.sourceUpdate |> Maybe.map (\_ -> SourceUpdateDialog.Close |> PSSourceUpdate |> ProjectSettingsMsg |> ModalClose) |> Maybe.withDefault (Noop "close-source-update") |> T.send
                            in
                            (sources |> List.findBy .id source.id)
                                |> Maybe.mapOrElse
                                    (\s ->
                                        ( sources |> List.mapBy .id source.id (Source.refreshWith source)
                                        , ( Cmd.batch [ close, Track.sourceRefreshed model.erd source ], [ ( PSSourceSet s, msg ) |> Tuple.map ProjectSettingsMsg ] )
                                        )
                                    )
                                    ( sources |> List.insert source
                                    , ( Cmd.batch [ close, Track.sourceAdded model.erd source ], [ ( PSSourceDelete source.id, msg ) |> Tuple.map ProjectSettingsMsg ] )
                                    )
                        )
                    )
                |> setHLDirtyCmd

        PSDefaultSchemaUpdate value ->
            model |> mapErdM (Erd.mapSettings (setDefaultSchema value)) |> setHDirty []

        PSSchemaToggle schema ->
            model |> mapErdM (Erd.mapSettings (mapRemovedSchemas (List.toggle schema))) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) )) |> setHDirtyCmd []

        PSRemoveViewsToggle ->
            model |> mapErdM (Erd.mapSettings (mapRemoveViews not)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) )) |> setHDirtyCmd []

        PSRemovedTablesUpdate values ->
            model |> mapErdM (Erd.mapSettings (setRemovedTables values >> ProjectSettings.fillFindPath)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) )) |> setHDirtyCmd []

        PSHiddenColumnsListUpdate values ->
            model |> mapErdM (Erd.mapSettings (mapHiddenColumns (setList values) >> ProjectSettings.fillFindPath)) |> setHDirty []

        PSHiddenColumnsMaxUpdate value ->
            value |> String.toInt |> Maybe.mapOrElse (\max -> model |> mapErdM (Erd.mapSettings (mapHiddenColumns (setMax max) >> ProjectSettings.fillFindPath))) model |> setHDirty []

        PSHiddenColumnsPropsToggle ->
            model |> mapErdM (Erd.mapSettings (mapHiddenColumns (mapProps not))) |> setHDirty []

        PSHiddenColumnsRelationsToggle ->
            model |> mapErdM (Erd.mapSettings (mapHiddenColumns (mapRelations not))) |> setHDirty []

        PSColumnOrderUpdate order ->
            model |> mapErdM (\e -> e |> Erd.mapSettings (setColumnOrder order)) |> setHDirty []

        PSRelationStyleUpdate style ->
            model |> mapErdM (\e -> e |> Erd.mapSettings (setRelationStyle style)) |> setHDirty []

        PSColumnBasicTypesToggle ->
            model |> mapErdM (Erd.mapSettings (mapColumnBasicTypes not)) |> setHDirty []

        PSCollapseTableOnShowToggle ->
            model |> mapErdM (Erd.mapSettings (mapCollapseTableColumns not)) |> setHDirty []


getShownTables : Maybe Erd -> List TableId
getShownTables erd =
    erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables >> List.map .id) []
