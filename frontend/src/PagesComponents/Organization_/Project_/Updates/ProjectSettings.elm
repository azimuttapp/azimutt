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
import Ports
import Services.Lenses exposing (mapCollapseTableColumns, mapColumnBasicTypes, mapEnabled, mapErdM, mapHiddenColumns, mapProps, mapRelations, mapRemoveViews, mapRemovedSchemas, mapSourceUpdateCmd, setColumnOrder, setDefaultSchema, setDirty, setList, setMax, setRelationStyle, setRemovedTables, setSettings)
import Services.Toasts as Toasts
import Time
import Track


type alias Model x =
    { x
        | dirty : Bool
        , erd : Maybe Erd
        , settings : Maybe ProjectSettingsDialog
        , sourceUpdate : Maybe (SourceUpdateDialog.Model Msg)
    }


handleProjectSettings : Time.Posix -> ProjectSettingsMsg -> Model x -> ( Model x, Cmd Msg )
handleProjectSettings now msg model =
    case msg of
        PSOpen ->
            ( model |> setSettings (Just { id = Conf.ids.settingsDialog }), Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.settingsDialog), Ports.track Track.openSettings ] )

        PSClose ->
            ( model |> setSettings Nothing, Cmd.none )

        PSSourceToggle source ->
            model
                |> setDirty True
                |> mapErdM (Erd.mapSource source.id (mapEnabled not))
                |> (\updated ->
                        ( updated
                        , Cmd.batch
                            [ Ports.observeTablesSize (updated.erd |> getShownTables)
                            , "Source " ++ source.name ++ " set to " ++ B.cond source.enabled "hidden" "visible" ++ "." |> Toasts.info |> Toast |> T.send
                            ]
                        )
                   )

        PSSourceDelete source ->
            ( model |> setDirty True |> mapErdM (Erd.mapSources (List.filter (\s -> s.id /= source.id))), "Source " ++ source.name ++ " has been deleted from your project." |> Toasts.info |> Toast |> T.send )

        PSSourceUpdate message ->
            model |> mapSourceUpdateCmd (SourceUpdateDialog.update (PSSourceUpdate >> ProjectSettingsMsg) ModalOpen Noop now message)

        PSSourceSet source ->
            if model.erd |> Maybe.mapOrElse (\erd -> erd.sources |> List.memberBy .id source.id) False then
                ( model |> setDirty True |> mapErdM (Erd.mapSource source.id (Source.refreshWith source)), Cmd.batch [ T.send (ModalClose (SourceUpdateDialog.Close |> PSSourceUpdate |> ProjectSettingsMsg)), Ports.track (Track.refreshSource source) ] )

            else
                ( model |> setDirty True |> mapErdM (Erd.mapSources (List.add source)), Cmd.batch [ T.send (ModalClose (SourceUpdateDialog.Close |> PSSourceUpdate |> ProjectSettingsMsg)), Ports.track (Track.addSource source) ] )

        PSDefaultSchemaUpdate value ->
            ( model |> setDirty True |> mapErdM (Erd.mapSettings (setDefaultSchema value)), Cmd.none )

        PSSchemaToggle schema ->
            model |> setDirty True |> mapErdM (Erd.mapSettings (mapRemovedSchemas (List.toggle schema))) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) ))

        PSRemoveViewsToggle ->
            model |> setDirty True |> mapErdM (Erd.mapSettings (mapRemoveViews not)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) ))

        PSRemovedTablesUpdate values ->
            model |> setDirty True |> mapErdM (Erd.mapSettings (setRemovedTables values >> ProjectSettings.fillFindPath)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) ))

        PSHiddenColumnsListUpdate values ->
            ( model |> setDirty True |> mapErdM (Erd.mapSettings (mapHiddenColumns (setList values) >> ProjectSettings.fillFindPath)), Cmd.none )

        PSHiddenColumnsMaxUpdate value ->
            ( value |> String.toInt |> Maybe.mapOrElse (\max -> model |> setDirty True |> mapErdM (Erd.mapSettings (mapHiddenColumns (setMax max) >> ProjectSettings.fillFindPath))) model, Cmd.none )

        PSHiddenColumnsPropsToggle ->
            ( model |> setDirty True |> mapErdM (Erd.mapSettings (mapHiddenColumns (mapProps not))), Cmd.none )

        PSHiddenColumnsRelationsToggle ->
            ( model |> setDirty True |> mapErdM (Erd.mapSettings (mapHiddenColumns (mapRelations not))), Cmd.none )

        PSColumnOrderUpdate order ->
            ( model |> setDirty True |> mapErdM (\e -> e |> Erd.mapSettings (setColumnOrder order)), Cmd.none )

        PSRelationStyleUpdate style ->
            ( model |> setDirty True |> mapErdM (\e -> e |> Erd.mapSettings (setRelationStyle style)), Cmd.none )

        PSColumnBasicTypesToggle ->
            ( model |> setDirty True |> mapErdM (Erd.mapSettings (mapColumnBasicTypes not)), Cmd.none )

        PSCollapseTableOnShowToggle ->
            ( model |> setDirty True |> mapErdM (Erd.mapSettings (mapCollapseTableColumns not)), Cmd.none )


getShownTables : Maybe Erd -> List TableId
getShownTables erd =
    erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables >> List.map .id) []
