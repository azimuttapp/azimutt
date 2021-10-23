module PagesComponents.App.Updates.ProjectSource exposing (handleProjectSource)

import Conf exposing (schemaSamples)
import Dict
import Libs.Maybe as M
import PagesComponents.App.Models exposing (Model, Msg(..), SourceMsg(..))
import PagesComponents.App.Updates.Helpers exposing (setSwitch)
import PagesComponents.App.Updates.Project exposing (addToProject, createProject)
import Ports exposing (readLocalFile, readRemoteFile, toastError)


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
                |> M.filter (\p -> p.id == projectId)
                |> Maybe.map (\_ -> model |> addToProject now projectId source content sample)
                |> Maybe.withDefault (model |> createProject now projectId source content sample)
