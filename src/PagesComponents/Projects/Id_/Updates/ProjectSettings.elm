module PagesComponents.Projects.Id_.Updates.ProjectSettings exposing (Model, handleProjectSettings)

import Conf
import Dict exposing (Dict)
import Libs.Bool as B
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ProjectSettings as ProjectSettings exposing (HiddenColumns)
import Models.Project.Source as Source
import Models.Project.TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectSettingsDialog, ProjectSettingsMsg(..), SourceUploadDialog)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import PagesComponents.Projects.Id_.Models.Notes exposing (Notes, NotesKey)
import Ports
import Services.Lenses exposing (mapCollapseTableColumns, mapColumnBasicTypes, mapEnabled, mapErdM, mapHiddenColumns, mapParsingCmd, mapProps, mapRelations, mapRemoveViews, mapRemovedSchemas, mapSourceUploadMCmd, mapTableProps, setColumnOrder, setList, setMax, setRelationStyle, setRemovedTables, setSettings, setSourceUpload)
import Services.SqlSourceUpload as SqlSourceUpload
import Services.Toasts as Toasts
import Track


type alias Model x =
    { x
        | erd : Maybe Erd
        , settings : Maybe ProjectSettingsDialog
        , sourceUpload : Maybe SourceUploadDialog
    }


handleProjectSettings : ProjectSettingsMsg -> Model x -> ( Model x, Cmd Msg )
handleProjectSettings msg model =
    case msg of
        PSOpen ->
            ( model |> setSettings (Just { id = Conf.ids.settingsDialog }), Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.settingsDialog), Ports.track Track.openSettings ] )

        PSClose ->
            ( model |> setSettings Nothing, Cmd.none )

        PSSourceToggle source ->
            ( model |> mapErdM (Erd.mapSource source.id (mapEnabled not))
            , Cmd.batch
                [ Ports.observeTablesSize (model.erd |> Maybe.mapOrElse .shownTables [])
                , Toasts.info Toast ("Source " ++ source.name ++ " set to " ++ B.cond source.enabled "hidden" "visible" ++ ".")
                ]
            )

        PSSourceDelete source ->
            ( model |> mapErdM (Erd.mapSources (List.filter (\s -> s.id /= source.id))), Toasts.info Toast ("Source " ++ source.name ++ " has been deleted from your project.") )

        PSSourceUploadOpen source ->
            ( model |> setSourceUpload (Just { id = Conf.ids.sourceUploadDialog, parsing = SqlSourceUpload.init (model.erd |> Maybe.map (\p -> p.project.id)) source (\_ -> Noop "project-settings-source-parsed") }), T.sendAfter 1 (ModalOpen Conf.ids.sourceUploadDialog) )

        PSSourceUploadClose ->
            ( model |> setSourceUpload Nothing, Cmd.none )

        PSSqlSourceMsg message ->
            model |> mapSourceUploadMCmd (mapParsingCmd (SqlSourceUpload.update message (PSSqlSourceMsg >> ProjectSettingsMsg)))

        PSSourceRefresh source ->
            ( model |> mapErdM (Erd.mapSource source.id (Source.refreshWith source)), Cmd.batch [ T.send (ModalClose (ProjectSettingsMsg PSSourceUploadClose)), Ports.track (Track.refreshSource source) ] )

        PSSourceAdd source ->
            ( model |> mapErdM (Erd.mapSources (\sources -> sources ++ [ source ])), Cmd.batch [ T.send (ModalClose (ProjectSettingsMsg PSSourceUploadClose)), Ports.track (Track.addSource source) ] )

        PSSchemaToggle schema ->
            model |> mapErdM (Erd.mapSettings (mapRemovedSchemas (List.toggle schema))) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> Maybe.mapOrElse .shownTables []) ))

        PSRemoveViewsToggle ->
            model |> mapErdM (Erd.mapSettings (mapRemoveViews not)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> Maybe.mapOrElse .shownTables []) ))

        PSRemovedTablesUpdate values ->
            model |> mapErdM (Erd.mapSettings (setRemovedTables values >> ProjectSettings.fillFindPath)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> Maybe.mapOrElse .shownTables []) ))

        PSHiddenColumnsListUpdate values ->
            ( model |> mapErdM (Erd.mapSettings (mapHiddenColumns (setList values) >> ProjectSettings.fillFindPath)) |> mapErdM (\e -> e |> mapTableProps (hideColumns e.tables e.notes e.settings.hiddenColumns)), Cmd.none )

        PSHiddenColumnsMaxUpdate value ->
            ( value |> String.toInt |> Maybe.mapOrElse (\max -> model |> mapErdM (Erd.mapSettings (mapHiddenColumns (setMax max) >> ProjectSettings.fillFindPath)) |> mapErdM (\e -> e |> mapTableProps (hideColumns e.tables e.notes e.settings.hiddenColumns))) model, Cmd.none )

        PSHiddenColumnsPropsToggle ->
            ( model |> mapErdM (Erd.mapSettings (mapHiddenColumns (mapProps not))) |> mapErdM (\e -> e |> mapTableProps (hideColumns e.tables e.notes e.settings.hiddenColumns)), Cmd.none )

        PSHiddenColumnsRelationsToggle ->
            ( model |> mapErdM (Erd.mapSettings (mapHiddenColumns (mapRelations not))) |> mapErdM (\e -> e |> mapTableProps (hideColumns e.tables e.notes e.settings.hiddenColumns)), Cmd.none )

        PSColumnOrderUpdate order ->
            ( model |> mapErdM (\e -> e |> Erd.mapSettings (setColumnOrder order) |> mapTableProps (sortColumns order e)), Cmd.none )

        PSRelationStyleUpdate style ->
            ( model |> mapErdM (\e -> e |> Erd.mapSettings (setRelationStyle style)), Cmd.none )

        PSColumnBasicTypesToggle ->
            ( model |> mapErdM (Erd.mapSettings (mapColumnBasicTypes not)), Cmd.none )

        PSCollapseTableOnShowToggle ->
            ( model |> mapErdM (Erd.mapSettings (mapCollapseTableColumns not)), Cmd.none )


hideColumns : Dict TableId ErdTable -> Dict NotesKey Notes -> HiddenColumns -> Dict TableId ErdTableProps -> Dict TableId ErdTableProps
hideColumns tables notes hiddenColumns tableProps =
    tableProps |> Dict.map (\tableId props -> tables |> Dict.get tableId |> Maybe.mapOrElse (\table -> props |> ErdTableProps.mapShownColumns (shouldHideColumns hiddenColumns table) notes) props)


shouldHideColumns : HiddenColumns -> ErdTable -> List ColumnName -> List ColumnName
shouldHideColumns hiddenColumns table columns =
    columns |> List.filterMap (\c -> table.columns |> Dict.get c) |> List.filterNot (ProjectSettings.hideColumn hiddenColumns) |> List.map .name


sortColumns : ColumnOrder -> Erd -> Dict TableId ErdTableProps -> Dict TableId ErdTableProps
sortColumns order erd tableProps =
    tableProps
        |> Dict.map
            (\id ->
                ErdTableProps.mapShownColumns
                    (\columnNames ->
                        (erd.tables |> Dict.get id)
                            |> Maybe.mapOrElse
                                (\table ->
                                    ColumnOrder.sortBy order
                                        table
                                        (erd.relations |> List.filter (\r -> r.src.table == id))
                                        (columnNames |> List.filterMap (\c -> table.columns |> Dict.get c))
                                        |> List.map .name
                                )
                                columnNames
                    )
                    erd.notes
            )
