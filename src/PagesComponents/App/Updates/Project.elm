module PagesComponents.App.Updates.Project exposing (addToProject, createProject, deleteProject, useProject)

import Conf exposing (conf)
import DataSources.SqlParser.FileParser exposing (parseSchema)
import DataSources.SqlParser.ProjectAdapter exposing (buildSourceFromSql)
import Dict
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (FileContent, TrackEvent)
import Libs.String as S
import Libs.Task as T
import Models.Project as Project exposing (Project, ProjectId, ProjectName, SourceInfo, SourceKind(..), extractPath)
import PagesComponents.App.Models exposing (Errors, Model, Msg(..), initSwitch)
import PagesComponents.App.Updates.Helpers exposing (setSources)
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
            extractPath sourceInfo.kind
    in
    (if path |> String.endsWith ".sql" then
        parseSchema content
            |> Tuple.mapSecond (\( lines, schema ) -> buildSourceFromSql sourceInfo lines schema)
            |> Tuple.mapSecond (\source -> Just (Project.create projectId (S.unique takenNames source.name) source))

     else
        ( [ "Invalid file (" ++ path ++ "), expected a .sql one" ], Nothing )
    )
        |> loadProject events.createProject model


addToProject : SourceInfo -> FileContent -> Project -> ( Project, Cmd Msg )
addToProject sourceInfo content project =
    let
        path : String
        path =
            extractPath sourceInfo.kind
    in
    if path |> String.endsWith ".sql" then
        case
            parseSchema content
                |> Tuple.mapSecond (\( lines, schema ) -> buildSourceFromSql sourceInfo lines schema)
                |> Tuple.mapSecond (\source -> ( project |> setSources (\sources -> sources ++ [ source ]), events.addSource source ))
        of
            ( errors, ( updatedProject, event ) ) ->
                ( updatedProject
                , Cmd.batch
                    ((errors |> List.map toastError)
                        ++ (errors |> List.map (trackError "parse-schema"))
                        ++ [ toastInfo ("<b>" ++ sourceInfo.name ++ "</b> loaded.")
                           , hideOffcanvas conf.ids.settings
                           , saveProject updatedProject
                           , track event
                           ]
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

                             else if Dict.size p.tables < 10 then
                                T.send ShowAllTables

                             else
                                click conf.ids.searchInput
                            )
                                :: [ toastInfo ("<b>" ++ p.name ++ "</b> loaded.<br>Use the search bar to explore it")
                                   , hideModal conf.ids.projectSwitchModal
                                   , saveProject p
                                   , activateTooltipsAndPopovers
                                   , track (projectEvent p)
                                   ]
                        )
                        []
               )
        )
    )
