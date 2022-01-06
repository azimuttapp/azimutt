module PagesComponents.Projects.Id_.Updates.ProjectSettings exposing (Model, handleProjectSettings)

import Dict
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
import PagesComponents.App.Updates.Helpers exposing (setLayout, setProject, setSettings)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectSettingsModel, ProjectSettingsMsg(..))
import Ports exposing (observeTablesSize)


type alias Model x =
    { x
        | project : Maybe Project
        , settings : Maybe ProjectSettingsModel
    }


handleProjectSettings : ProjectSettingsMsg -> Model x -> ( Model x, Cmd Msg )
handleProjectSettings msg model =
    case msg of
        PSOpen ->
            ( { model | settings = Just () }, T.sendAfter 1 ModalOpen )

        PSClose ->
            ( { model | settings = Nothing }, Cmd.none )

        ToggleSchema schema ->
            model |> updateSettingsAndComputeProject (\s -> { s | removedSchemas = s.removedSchemas |> L.toggle schema })

        ToggleRemoveViews ->
            model |> updateSettingsAndComputeProject (\s -> { s | removeViews = not s.removeViews })

        UpdateRemovedTables values ->
            model |> updateSettingsAndComputeProject (\s -> { s | removedTables = values })

        UpdateHiddenColumns values ->
            ( model |> setProject (\p -> p |> setSettings (\s -> { s | hiddenColumns = values }) |> setLayout (hideColumns (ProjectSettings.isColumnHidden values) p)), Cmd.none )

        UpdateColumnOrder order ->
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
