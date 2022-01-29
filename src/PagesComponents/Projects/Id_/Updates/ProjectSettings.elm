module PagesComponents.Projects.Id_.Updates.ProjectSettings exposing (Model, handleProjectSettings)

import Conf
import Dict exposing (Dict)
import Libs.Bool as B
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Ned as Ned
import Libs.Task as T
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ProjectSettings as ProjectSettings
import Models.Project.Source as Source
import Models.Project.TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectSettingsDialog, ProjectSettingsMsg(..), SourceUploadDialog, toastInfo)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import Ports
import Services.Lenses exposing (mapEnabled, mapErdM, mapParsingCmd, mapRemoveViews, mapRemovedSchemas, mapSourceUploadMCmd, mapTableProps, setColumnOrder, setHiddenColumns, setRemovedTables, setSettings, setSourceUpload)
import Services.SQLSource as SQLSource
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

        PSToggleSource source ->
            ( model |> mapErdM (Erd.mapSource source.id (mapEnabled not))
            , Cmd.batch
                [ Ports.observeTablesSize (model.erd |> Maybe.mapOrElse .shownTables [])
                , T.send (toastInfo ("Source " ++ source.name ++ " set to " ++ B.cond source.enabled "hidden" "visible" ++ "."))
                ]
            )

        PSDeleteSource source ->
            ( model |> mapErdM (Erd.mapSources (List.filter (\s -> s.id /= source.id))), T.send (toastInfo ("Source " ++ source.name ++ " has been deleted from your project.")) )

        PSSourceUploadOpen source ->
            ( model |> setSourceUpload (Just { id = Conf.ids.sourceUploadDialog, parsing = SQLSource.init (model.erd |> Maybe.map (\p -> p.project.id)) source }), T.sendAfter 1 (ModalOpen Conf.ids.sourceUploadDialog) )

        PSSourceUploadClose ->
            ( model |> setSourceUpload Nothing, Cmd.none )

        PSSQLSourceMsg message ->
            model |> mapSourceUploadMCmd (mapParsingCmd (SQLSource.update message (PSSQLSourceMsg >> ProjectSettingsMsg)))

        PSSourceRefresh source ->
            ( model |> mapErdM (Erd.mapSource source.id (Source.refreshWith source)), Cmd.batch [ T.send (ModalClose (ProjectSettingsMsg PSSourceUploadClose)), Ports.track (Track.refreshSource source) ] )

        PSSourceAdd source ->
            ( model |> mapErdM (Erd.mapSources (\sources -> sources ++ [ source ])), Cmd.batch [ T.send (ModalClose (ProjectSettingsMsg PSSourceUploadClose)), Ports.track (Track.addSource source) ] )

        PSToggleSchema schema ->
            model |> mapErdM (Erd.mapSettings (mapRemovedSchemas (List.toggle schema))) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> Maybe.mapOrElse .shownTables []) ))

        PSToggleRemoveViews ->
            model |> mapErdM (Erd.mapSettings (mapRemoveViews not)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> Maybe.mapOrElse .shownTables []) ))

        PSUpdateRemovedTables values ->
            model |> mapErdM (Erd.mapSettings (setRemovedTables values)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> Maybe.mapOrElse .shownTables []) ))

        PSUpdateHiddenColumns values ->
            ( model |> mapErdM (\e -> e |> Erd.mapSettings (setHiddenColumns values) |> mapTableProps (hideColumns (ProjectSettings.isColumnHidden values))), Cmd.none )

        PSUpdateColumnOrder order ->
            ( model |> mapErdM (\e -> e |> Erd.mapSettings (setColumnOrder order) |> mapTableProps (sortColumns order e)), Cmd.none )


hideColumns : (ColumnName -> Bool) -> Dict TableId ErdTableProps -> Dict TableId ErdTableProps
hideColumns isColumnHidden tableProps =
    tableProps |> Dict.map (\_ -> ErdTableProps.mapShownColumns (List.filterNot isColumnHidden))


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
                                        (columnNames |> List.filterMap (\c -> table.columns |> Ned.get c))
                                        |> List.map .name
                                )
                                columnNames
                    )
            )
