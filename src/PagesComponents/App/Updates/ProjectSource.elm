module PagesComponents.App.Updates.ProjectSource exposing (handleProjectSource)

import Conf exposing (schemaSamples)
import Dict
import Libs.Bool as B
import Libs.Maybe as M
import PagesComponents.App.Models exposing (Model, Msg(..), SourceMsg(..))
import PagesComponents.App.Updates.Helpers exposing (setProject, setSwitch)
import PagesComponents.App.Updates.Project exposing (addToProject, createProject)
import Ports exposing (observeTablesSize, readLocalFile, readRemoteFile, toastError)


handleProjectSource : SourceMsg -> Model -> ( Model, Cmd Msg )
handleProjectSource msg model =
    case msg of
        FileDragOver _ _ ->
            ( model, Cmd.none )

        FileDragLeave ->
            ( model, Cmd.none )

        FileDropped project file _ ->
            ( model |> setSwitch (\s -> { s | loading = True }), readLocalFile project file )

        FileSelected project file ->
            ( model |> setSwitch (\s -> { s | loading = True }), readLocalFile project file )

        LoadSample name ->
            ( model, schemaSamples |> Dict.get name |> Maybe.map (\( _, url ) -> readRemoteFile url (Just name)) |> Maybe.withDefault (toastError ("Sample <b>" ++ name ++ "</b> not found")) )

        FileLoaded now projectId source content sample ->
            model.project
                |> M.filter (\project -> project.id == projectId)
                |> Maybe.map (\project -> project |> addToProject now source content |> Tuple.mapFirst (\p -> { model | project = Just p }))
                |> Maybe.withDefault (model |> createProject now projectId source content sample)

        ToggleSource sourceId ->
            ( model |> setProject (\p -> { p | sources = p.sources |> List.map (\s -> B.cond (s.id == sourceId) { s | enabled = not s.enabled } s) })
            , observeTablesSize (model.project |> Maybe.map (\p -> p.schema.layout.tables |> List.map .id) |> Maybe.withDefault [])
            )
