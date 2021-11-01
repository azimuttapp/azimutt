module PagesComponents.App.Updates.Settings exposing (handleSettings)

import Libs.List as L
import Libs.Maybe as M
import Models.Project as Project
import Models.Project.ProjectSettings exposing (ProjectSettings)
import PagesComponents.App.Models exposing (Model, Msg, SettingsMsg(..))
import PagesComponents.App.Updates.Helpers exposing (setProject, setSettings)
import Ports exposing (observeTablesSize)


handleSettings : SettingsMsg -> Model -> ( Model, Cmd Msg )
handleSettings msg model =
    case msg of
        ToggleSchema schema ->
            model |> updateSettingsAndComputeProject (\s -> { s | removedSchemas = s.removedSchemas |> L.toggle schema })

        ToggleRemoveViews ->
            model |> updateSettingsAndComputeProject (\s -> { s | removeViews = not s.removeViews })

        UpdateRemovedTables values ->
            model |> updateSettingsAndComputeProject (\s -> { s | removedTables = values })

        UpdateHiddenColumns values ->
            model |> updateSettingsAndComputeProject (\s -> { s | hiddenColumns = values })

        UpdateColumnOrder order ->
            model |> updateSettingsAndComputeProject (\s -> { s | columnOrder = order })


updateSettingsAndComputeProject : (ProjectSettings -> ProjectSettings) -> Model -> ( Model, Cmd Msg )
updateSettingsAndComputeProject transform model =
    model
        |> setProject (setSettings transform >> Project.compute)
        |> (\m -> ( m, observeTablesSize (m.project |> M.mapOrElse (\p -> p.layout.tables |> List.map .id) []) ))
