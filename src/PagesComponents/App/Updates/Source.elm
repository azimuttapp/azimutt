module PagesComponents.App.Updates.Source exposing (handleSource)

import Conf exposing (schemaSamples)
import Dict
import Libs.Bool as B
import Libs.Maybe as M
import PagesComponents.App.Models exposing (Model, Msg(..), SourceMsg(..))
import PagesComponents.App.Updates.Helpers exposing (setProject, setSources, setSwitch)
import PagesComponents.App.Updates.Project exposing (addToProject, createProject)
import Ports exposing (observeTablesSize, readLocalFile, readRemoteFile, toastError)


handleSource : SourceMsg -> Model -> ( Model, Cmd Msg )
handleSource msg model =
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
            ( model, schemaSamples |> Dict.get name |> M.mapOrElse (\( _, url ) -> readRemoteFile url (Just name)) (toastError ("Sample <b>" ++ name ++ "</b> not found")) )

        FileLoaded projectId sourceInfo content ->
            model.project
                |> M.filter (\project -> project.id == projectId)
                |> M.mapOrElse (\project -> project |> addToProject sourceInfo content |> Tuple.mapFirst (\p -> { model | project = Just p }))
                    (model |> createProject projectId sourceInfo content)

        ToggleSource sourceId ->
            ( model |> setProject (setSources (List.map (\s -> B.cond (s.id == sourceId) { s | enabled = not s.enabled } s)))
            , observeTablesSize (model.project |> M.mapOrElse (\p -> p.layout.tables |> List.map .id) [])
            )

        DeleteSource sourceId ->
            ( model |> setProject (setSources (List.filter (\s -> s.id /= sourceId))), Cmd.none )
