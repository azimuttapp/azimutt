module PagesComponents.App.Updates.Project exposing (createProject, deleteProject, updateProject, useProject)

import Conf
import DataSources.SqlParser.FileParser exposing (parseSchema)
import DataSources.SqlParser.ProjectAdapter exposing (buildSourceFromSql)
import Dict
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (FileContent, TrackEvent)
import Libs.String as S
import Libs.Task as T
import Models.Project as Project exposing (Project)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.SourceKind as SourceKind
import Models.SourceInfo exposing (SourceInfo)
import PagesComponents.App.Models exposing (Errors, Model, Msg(..), initSwitch)
import Ports exposing (activateTooltipsAndPopovers, click, dropProject, hideModal, hideOffcanvas, observeTablesSize, saveProject, toastError, toastInfo, track, trackError)
import Tracking exposing (events)


createProject : ProjectId -> SourceInfo -> FileContent -> Model -> ( Model, Cmd Msg )
createProject projectId sourceInfo content model =
    let
        takenNames : List ProjectName
        takenNames =
            model.storedProjects |> List.map .name

        path : String
        path =
            sourceInfo.kind |> SourceKind.path
    in
    (if path |> String.endsWith ".sql" then
        parseSchema content
            |> Tuple.mapSecond (\( lines, schema ) -> buildSourceFromSql sourceInfo lines schema)
            |> Tuple.mapSecond (\source -> Just (Project.create projectId (S.unique takenNames source.name) source))

     else
        ( [ "Invalid file (" ++ path ++ "), expected a .sql one" ], Nothing )
    )
        |> loadProject events.createProject model


updateProject : SourceInfo -> FileContent -> Project -> ( Project, Cmd Msg )
updateProject sourceInfo content project =
    let
        path : String
        path =
            sourceInfo.kind |> SourceKind.path
    in
    if path |> String.endsWith ".sql" then
        (parseSchema content
            |> Tuple.mapSecond (\( lines, schema ) -> buildSourceFromSql sourceInfo lines schema)
            |> Tuple.mapSecond
                (\newSource ->
                    project.sources
                        |> L.find (\s -> s.id == newSource.id)
                        |> Maybe.map
                            (\oldSource ->
                                ( project |> Project.updateSource newSource.id (\_ -> newSource)
                                , events.refreshSource newSource
                                , "Source <b>" ++ oldSource.name ++ "</b> updated with <b>" ++ newSource.name ++ "</b>."
                                )
                            )
                        |> Maybe.withDefault
                            ( project |> Project.addSource newSource
                            , events.addSource newSource
                            , "Source <b>" ++ newSource.name ++ "</b> added to project."
                            )
                )
        )
            |> (\( errors, ( updatedProject, event, message ) ) ->
                    ( updatedProject
                    , Cmd.batch
                        ((errors |> List.map toastError)
                            ++ (errors |> List.map (trackError "parse-schema"))
                            ++ [ toastInfo message
                               , hideOffcanvas Conf.ids.settingsDialog
                               , saveProject updatedProject
                               , track event
                               ]
                        )
                    )
               )

    else
        ( project, toastError ("Invalid file (" ++ path ++ "), expected .sql") )


useProject : Project -> Model -> ( Model, Cmd Msg )
useProject project model =
    ( [], Just project ) |> loadProject events.loadProject model


deleteProject : Project -> Model -> ( Model, Cmd Msg )
deleteProject project model =
    ( { model | storedProjects = model.storedProjects |> List.filter (\p -> not (p.id == project.id)) }, Cmd.batch [ dropProject project, track (events.deleteProject project) ] )


loadProject : (Project -> TrackEvent) -> Model -> ( Errors, Maybe Project ) -> ( Model, Cmd Msg )
loadProject projectEvent model ( errors, project ) =
    ( { model
        | switch = initSwitch
        , storedProjects = model.storedProjects |> L.appendOn (project |> M.filter (\p -> model.storedProjects |> List.all (\s -> s.name /= p.name))) identity
        , project = project
        , domInfos = model.domInfos |> Dict.filter (\id _ -> not (id |> String.startsWith "table-"))
      }
    , Cmd.batch
        ((errors |> List.map toastError)
            ++ (errors |> List.map (trackError "parse-project"))
            ++ (project
                    |> M.mapOrElse
                        (\p ->
                            (if not (p.layout.tables |> List.isEmpty) then
                                observeTablesSize (p.layout.tables |> List.map .id)

                             else if Dict.size p.tables < Conf.canvas.showAllTablesThreshold then
                                T.send ShowAllTables

                             else
                                click Conf.ids.searchInput
                            )
                                :: [ toastInfo ("<b>" ++ p.name ++ "</b> loaded.<br>Use the search bar to explore it")
                                   , hideModal Conf.ids.projectSwitchModal
                                   , saveProject p
                                   , activateTooltipsAndPopovers
                                   , track (projectEvent p)
                                   ]
                        )
                        []
               )
        )
    )
