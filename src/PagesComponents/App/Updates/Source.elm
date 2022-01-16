module PagesComponents.App.Updates.Source exposing (handleSource)

import Conf
import Dict
import Libs.Bool as B
import Libs.Maybe as M
import Models.Project as Project
import PagesComponents.App.Models exposing (Model, Msg(..), SourceMsg(..))
import PagesComponents.App.Updates.Project exposing (createProject, updateProject)
import Ports
import Services.Lenses exposing (setProject, setSwitch)


handleSource : SourceMsg -> Model -> ( Model, Cmd Msg )
handleSource msg model =
    case msg of
        FileDragOver _ _ ->
            ( model, Cmd.none )

        FileDragLeave ->
            ( model, Cmd.none )

        LoadLocalFile project source file ->
            ( model |> setSwitch (\s -> { s | loading = True }), Ports.readLocalFile project source file )

        LoadRemoteFile project source url ->
            ( model, Ports.readRemoteFile project source url Nothing )

        LoadSample key ->
            ( model, Conf.schemaSamples |> Dict.get key |> M.mapOrElse (\sample -> Ports.readRemoteFile Nothing Nothing sample.url (Just sample.name)) (Ports.toastError ("Sample <b>" ++ key ++ "</b> not found")) )

        FileLoaded projectId sourceInfo content ->
            model.project
                |> M.filter (\project -> project.id == projectId)
                |> M.mapOrElse
                    (\project -> project |> updateProject sourceInfo content |> Tuple.mapFirst (\p -> { model | project = Just p }))
                    (model |> createProject projectId sourceInfo content)

        ToggleSource source ->
            ( model |> setProject (Project.updateSource source.id (\s -> { s | enabled = not s.enabled }))
            , Cmd.batch
                [ Ports.observeTablesSize (model.project |> M.mapOrElse (\p -> p.layout.tables |> List.map .id) [])
                , Ports.toastInfo ("Source <b>" ++ source.name ++ "</b> set to " ++ B.cond source.enabled "hidden" "visible" ++ ".")
                ]
            )

        CreateSource source message ->
            ( model |> setProject (Project.addSource source), Ports.toastInfo message )

        DeleteSource source ->
            ( model |> setProject (Project.deleteSource source.id), Ports.toastInfo ("Source <b>" ++ source.name ++ "</b> has been deleted from project.") )
