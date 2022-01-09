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
import Ports exposing (observeTablesSize)
import Services.Lenses exposing (setLayout, setParsingWithCmd, setProject, setSettings, setSourceUploadWithCmd)
import Services.SQLSource as SQLSource


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
            ( { model | settings = Just { id = Conf.ids.settingsDialog } }, T.sendAfter 1 (ModalOpen Conf.ids.settingsDialog) )

        PSClose ->
            ( { model | settings = Nothing }, Cmd.none )

        PSToggleSource source ->
            ( model |> setProject (Project.updateSource source.id (\s -> { s | enabled = not s.enabled }))
            , Cmd.batch
                [ observeTablesSize (model.project |> M.mapOrElse (\p -> p.layout.tables |> List.map .id) [])
                , T.send (toastInfo ("Source " ++ source.name ++ " set to " ++ B.cond source.enabled "hidden" "visible" ++ "."))
                ]
            )

        PSDeleteSource source ->
            ( model |> setProject (Project.deleteSource source.id), T.send (toastInfo ("Source " ++ source.name ++ " has been deleted from your project.")) )

        PSSourceUploadOpen source ->
            ( { model | sourceUpload = Just { id = Conf.ids.sourceUploadDialog, parsing = SQLSource.init model.project source } }, T.sendAfter 1 (ModalOpen Conf.ids.sourceUploadDialog) )

        PSSourceUploadClose ->
            ( { model | sourceUpload = Nothing }, Cmd.none )

        PSSQLSourceMsg message ->
            model |> setSourceUploadWithCmd (setParsingWithCmd (SQLSource.update message (PSSQLSourceMsg >> ProjectSettingsMsg)))

        PSSourceRefresh source ->
            ( model |> setProject (Project.refreshSource source), T.send (ModalClose (ProjectSettingsMsg PSSourceUploadClose)) )

        PSSourceAdd source ->
            ( model |> setProject (Project.addSource source), T.send (ModalClose (ProjectSettingsMsg PSSourceUploadClose)) )

        PSToggleSchema schema ->
            model |> updateSettingsAndComputeProject (\s -> { s | removedSchemas = s.removedSchemas |> L.toggle schema })

        PSToggleRemoveViews ->
            model |> updateSettingsAndComputeProject (\s -> { s | removeViews = not s.removeViews })

        PSUpdateRemovedTables values ->
            model |> updateSettingsAndComputeProject (\s -> { s | removedTables = values })

        PSUpdateHiddenColumns values ->
            ( model |> setProject (\p -> p |> setSettings (\s -> { s | hiddenColumns = values }) |> setLayout (hideColumns (ProjectSettings.isColumnHidden values) p)), Cmd.none )

        PSUpdateColumnOrder order ->
            ( model |> setProject (\p -> p |> setSettings (\s -> { s | columnOrder = order }) |> setLayout (sortColumns order p)), Cmd.none )


updateSettingsAndComputeProject : (ProjectSettings -> ProjectSettings) -> Model x -> ( Model x, Cmd Msg )
updateSettingsAndComputeProject transform model =
    model
        |> setProject (setSettings transform >> Project.compute)
        |> (\m -> ( m, observeTablesSize (m.project |> M.mapOrElse (\p -> p.layout.tables |> List.map .id) []) ))


hideColumns : (Column -> Bool) -> Project -> Layout -> Layout
hideColumns isColumnHidden project layout =
    { layout
        | tables = layout.tables |> List.map (hideTableColumns isColumnHidden project)
        , hiddenTables = layout.hiddenTables |> List.map (hideTableColumns isColumnHidden project)
    }


sortColumns : ColumnOrder -> Project -> Layout -> Layout
sortColumns order project layout =
    { layout
        | tables = layout.tables |> List.map (sortTableColumns order project)
        , hiddenTables = layout.hiddenTables |> List.map (sortTableColumns order project)
    }


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
