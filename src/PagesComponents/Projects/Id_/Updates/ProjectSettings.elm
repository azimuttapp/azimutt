module PagesComponents.Projects.Id_.Updates.ProjectSettings exposing (Model, handleProjectSettings)

import Conf
import Dict
import Libs.Bool as B
import Libs.List as L
import Libs.Maybe as M
import Libs.Ned as Ned
import Libs.Task as T
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.Project as Project exposing (Project)
import Models.Project.Column exposing (Column)
import Models.Project.Layout exposing (Layout)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import Models.Project.Table exposing (Table)
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectSettingsDialog, ProjectSettingsMsg(..), SourceUploadDialog, toastInfo)
import Ports
import Services.Lenses exposing (mapEnabled, mapHiddenTables, mapLayout, mapParsingCmd, mapProjectM, mapRemoveViews, mapRemovedSchemas, mapSettings, mapSourceUploadMCmd, mapTables, setColumnOrder, setHiddenColumns, setRemovedTables, setSettings, setSourceUpload)
import Services.SQLSource as SQLSource
import Track


type alias Model x =
    { x
        | project : Maybe Project
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
            ( model |> mapProjectM (Project.updateSource source.id (mapEnabled not))
            , Cmd.batch
                [ Ports.observeTablesSize (model.project |> M.mapOrElse (\p -> p.layout.tables |> List.map .id) [])
                , T.send (toastInfo ("Source " ++ source.name ++ " set to " ++ B.cond source.enabled "hidden" "visible" ++ "."))
                ]
            )

        PSDeleteSource source ->
            ( model |> mapProjectM (Project.deleteSource source.id), T.send (toastInfo ("Source " ++ source.name ++ " has been deleted from your project.")) )

        PSSourceUploadOpen source ->
            ( model |> setSourceUpload (Just { id = Conf.ids.sourceUploadDialog, parsing = SQLSource.init model.project source }), T.sendAfter 1 (ModalOpen Conf.ids.sourceUploadDialog) )

        PSSourceUploadClose ->
            ( model |> setSourceUpload Nothing, Cmd.none )

        PSSQLSourceMsg message ->
            model |> mapSourceUploadMCmd (mapParsingCmd (SQLSource.update message (PSSQLSourceMsg >> ProjectSettingsMsg)))

        PSSourceRefresh source ->
            ( model |> mapProjectM (Project.refreshSource source), Cmd.batch [ T.send (ModalClose (ProjectSettingsMsg PSSourceUploadClose)), Ports.track (Track.refreshSource source) ] )

        PSSourceAdd source ->
            ( model |> mapProjectM (Project.addSource source), Cmd.batch [ T.send (ModalClose (ProjectSettingsMsg PSSourceUploadClose)), Ports.track (Track.addSource source) ] )

        PSToggleSchema schema ->
            model |> updateSettingsAndComputeProject (mapRemovedSchemas (L.toggle schema))

        PSToggleRemoveViews ->
            model |> updateSettingsAndComputeProject (mapRemoveViews not)

        PSUpdateRemovedTables values ->
            model |> updateSettingsAndComputeProject (setRemovedTables values)

        PSUpdateHiddenColumns values ->
            ( model |> mapProjectM (\p -> p |> mapSettings (setHiddenColumns values) |> mapLayout (hideColumns (ProjectSettings.isColumnHidden values) p)), Cmd.none )

        PSUpdateColumnOrder order ->
            ( model |> mapProjectM (\p -> p |> mapSettings (setColumnOrder order) |> mapLayout (sortColumns order p)), Cmd.none )


updateSettingsAndComputeProject : (ProjectSettings -> ProjectSettings) -> Model x -> ( Model x, Cmd Msg )
updateSettingsAndComputeProject transform model =
    model
        |> mapProjectM (mapSettings transform >> Project.compute)
        |> (\m -> ( m, Ports.observeTablesSize (m.project |> M.mapOrElse (\p -> p.layout.tables |> List.map .id) []) ))


hideColumns : (Column -> Bool) -> Project -> Layout -> Layout
hideColumns isColumnHidden project layout =
    layout
        |> mapTables (List.map (hideTableColumns isColumnHidden project))
        |> mapHiddenTables (List.map (hideTableColumns isColumnHidden project))


sortColumns : ColumnOrder -> Project -> Layout -> Layout
sortColumns order project layout =
    layout
        |> mapTables (List.map (sortTableColumns order project))
        |> mapHiddenTables (List.map (sortTableColumns order project))


hideTableColumns : (Column -> Bool) -> Project -> TableProps -> TableProps
hideTableColumns isColumnHidden project props =
    updateProps (\_ -> L.filterNot isColumnHidden) project props


sortTableColumns : ColumnOrder -> Project -> TableProps -> TableProps
sortTableColumns order project props =
    updateProps (\table -> ColumnOrder.sortBy order table (project.relations |> List.filter (\r -> r.src.table == table.id))) project props


updateProps : (Table -> List Column -> List Column) -> Project -> TableProps -> TableProps
updateProps transform project props =
    project.tables
        |> Dict.get props.id
        |> M.mapOrElse
            (\table ->
                { props
                    | columns =
                        props.columns
                            |> List.filterMap (\c -> table.columns |> Ned.get c)
                            |> transform table
                            |> List.map .name
                }
            )
            props
