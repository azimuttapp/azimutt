module PagesComponents.Organization_.Project_.Updates.ProjectSettings exposing (Model, handleProjectSettings)

import Conf
import Libs.Bool as B
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project.ProjectSettings as ProjectSettings
import Models.Project.Source as Source
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), ProjectSettingsDialog, ProjectSettingsMsg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty, setDirtyCmd)
import Ports
import Services.Lenses exposing (mapCollapseTableColumns, mapColumnBasicTypes, mapEnabled, mapErdM, mapHiddenColumns, mapProps, mapRelations, mapRemoveViews, mapRemovedSchemas, mapSettingsM, mapSourceUpdateCmd, setColumnOrder, setDefaultSchema, setList, setMax, setName, setRelationStyle, setRemovedTables, setSettings)
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


handleProjectSettings : Time.Posix -> ProjectSettingsMsg -> Model x -> ( Model x, Cmd Msg )
handleProjectSettings now msg model =
    case msg of
        PSOpen ->
            ( model |> setSettings (Just { id = Conf.ids.settingsDialog, sourceNameEdit = Nothing }), Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.settingsDialog) ] )

        PSClose ->
            ( model |> setSettings Nothing, Cmd.none )

        PSSourceToggle source ->
            model
                |> mapErdM (Erd.mapSource source.id (mapEnabled not))
                |> (\updated ->
                        ( updated
                        , Cmd.batch
                            [ Ports.observeTablesSize (updated.erd |> getShownTables)
                            , "Source " ++ source.name ++ " set to " ++ B.cond source.enabled "hidden" "visible" ++ "." |> Toasts.info |> Toast |> T.send
                            ]
                        )
                   )
                |> setDirtyCmd

        PSSourceNameUpdate source name ->
            ( model |> mapSettingsM (\s -> { s | sourceNameEdit = Just source }) |> mapErdM (Erd.mapSource source (setName name)), Cmd.none )

        PSSourceNameUpdateDone ->
            ( model |> mapSettingsM (\s -> { s | sourceNameEdit = Nothing }), Cmd.none )

        PSSourceDelete source ->
            ( model |> mapErdM (Erd.mapSources (List.filter (\s -> s.id /= source.id))), Cmd.batch [ "Source " ++ source.name ++ " has been deleted from your project." |> Toasts.info |> Toast |> T.send, Track.sourceDeleted model.erd source ] ) |> setDirtyCmd

        PSSourceUpdate message ->
            model |> mapSourceUpdateCmd (SourceUpdateDialog.update (PSSourceUpdate >> ProjectSettingsMsg) ModalOpen Noop now (model.erd |> Maybe.map .project) message)

        PSSourceSet source ->
            if model.erd |> Maybe.mapOrElse (\erd -> erd.sources |> List.memberBy .id source.id) False then
                ( model |> mapErdM (Erd.mapSource source.id (Source.refreshWith source)), Cmd.batch [ T.send (ModalClose (SourceUpdateDialog.Close |> PSSourceUpdate |> ProjectSettingsMsg)), Track.sourceRefreshed model.erd source ] ) |> setDirtyCmd

            else
                ( model |> mapErdM (Erd.mapSources (List.add source)), Cmd.batch [ T.send (ModalClose (SourceUpdateDialog.Close |> PSSourceUpdate |> ProjectSettingsMsg)), Track.sourceAdded model.erd source ] ) |> setDirtyCmd

        PSDefaultSchemaUpdate value ->
            model |> mapErdM (Erd.mapSettings (setDefaultSchema value)) |> setDirty

        PSSchemaToggle schema ->
            model |> mapErdM (Erd.mapSettings (mapRemovedSchemas (List.toggle schema))) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) )) |> setDirtyCmd

        PSRemoveViewsToggle ->
            model |> mapErdM (Erd.mapSettings (mapRemoveViews not)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) )) |> setDirtyCmd

        PSRemovedTablesUpdate values ->
            model |> mapErdM (Erd.mapSettings (setRemovedTables values >> ProjectSettings.fillFindPath)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) )) |> setDirtyCmd

        PSHiddenColumnsListUpdate values ->
            model |> mapErdM (Erd.mapSettings (mapHiddenColumns (setList values) >> ProjectSettings.fillFindPath)) |> setDirty

        PSHiddenColumnsMaxUpdate value ->
            value |> String.toInt |> Maybe.mapOrElse (\max -> model |> mapErdM (Erd.mapSettings (mapHiddenColumns (setMax max) >> ProjectSettings.fillFindPath))) model |> setDirty

        PSHiddenColumnsPropsToggle ->
            model |> mapErdM (Erd.mapSettings (mapHiddenColumns (mapProps not))) |> setDirty

        PSHiddenColumnsRelationsToggle ->
            model |> mapErdM (Erd.mapSettings (mapHiddenColumns (mapRelations not))) |> setDirty

        PSColumnOrderUpdate order ->
            model |> mapErdM (\e -> e |> Erd.mapSettings (setColumnOrder order)) |> setDirty

        PSRelationStyleUpdate style ->
            model |> mapErdM (\e -> e |> Erd.mapSettings (setRelationStyle style)) |> setDirty

        PSColumnBasicTypesToggle ->
            model |> mapErdM (Erd.mapSettings (mapColumnBasicTypes not)) |> setDirty

        PSCollapseTableOnShowToggle ->
            model |> mapErdM (Erd.mapSettings (mapCollapseTableColumns not)) |> setDirty


getShownTables : Maybe Erd -> List TableId
getShownTables erd =
    erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables >> List.map .id) []
