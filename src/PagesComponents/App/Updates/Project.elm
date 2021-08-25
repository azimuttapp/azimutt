module PagesComponents.App.Updates.Project exposing (createProjectFromFile, createProjectFromUrl, useProject)

import Conf exposing (conf)
import DataSources.SqlParser.FileParser exposing (parseSchema)
import DataSources.SqlParser.ProjectAdapter exposing (buildProjectFromSql)
import Dict
import FileValue exposing (File)
import Json.Decode as Decode
import Libs.Bool exposing (cond)
import Libs.List as L
import Libs.Models exposing (FileContent, FileUrl)
import Libs.Result as R
import Libs.Task as T
import Models.Project exposing (Project, ProjectId, ProjectName, ProjectSource, ProjectSourceContent(..), ProjectSourceId, decodeProject, extractPath)
import PagesComponents.App.Models exposing (Errors, Model, Msg(..), initSwitch)
import PagesComponents.App.Updates.Helpers exposing (decodeErrorToHtml)
import Ports exposing (activateTooltipsAndPopovers, click, hideModal, observeTablesSize, saveProject, toastError, toastInfo, trackErrorList, trackProjectEvent)
import Time


useProject : Project -> Model -> ( Model, Cmd Msg )
useProject project model =
    ( [], Just project ) |> loadProject model


createProjectFromFile : Time.Posix -> ProjectId -> ProjectSourceId -> File -> FileContent -> Model -> ( Model, Cmd Msg )
createProjectFromFile now projectId sourceId file content model =
    buildProject (model.storedProjects |> List.map .name) now projectId (localSource now sourceId file) content
        |> (\r -> loadProject model r)


createProjectFromUrl : Time.Posix -> ProjectId -> ProjectSourceId -> FileUrl -> FileContent -> Model -> ( Model, Cmd Msg )
createProjectFromUrl now projectId sourceId path content model =
    buildProject (model.storedProjects |> List.map .name) now projectId (remoteSource now sourceId path content) content
        |> (\r -> loadProject model r)


loadProject : Model -> ( Errors, Maybe Project ) -> ( Model, Cmd Msg )
loadProject model ( errs, project ) =
    ( { model | switch = initSwitch, project = project, sizes = model.sizes |> Dict.filter (\id _ -> not (id |> String.startsWith "table-")) }
    , Cmd.batch
        ((errs |> List.map toastError)
            ++ cond (List.isEmpty errs) [] [ trackErrorList "parse-project" errs ]
            ++ (project
                    |> Maybe.map
                        (\p ->
                            (if not (p.schema.layout.tables |> List.isEmpty) then
                                observeTablesSize (p.schema.layout.tables |> List.map .id)

                             else if Dict.size p.schema.tables < 10 then
                                T.send ShowAllTables

                             else
                                click conf.ids.searchInput
                            )
                                :: [ toastInfo ("<b>" ++ p.name ++ "</b> loaded.<br>Use the search bar to explore it")
                                   , hideModal conf.ids.projectSwitchModal
                                   , saveProject p
                                   , activateTooltipsAndPopovers
                                   , trackProjectEvent "load" p
                                   ]
                        )
                    |> Maybe.withDefault []
               )
        )
    )


buildProject : List ProjectName -> Time.Posix -> ProjectId -> ProjectSource -> FileContent -> ( Errors, Maybe Project )
buildProject takenNames now projectId source content =
    let
        path : String
        path =
            extractPath source.source
    in
    if path |> String.endsWith ".sql" then
        parseSchema path content |> Tuple.mapSecond (\s -> Just (buildProjectFromSql takenNames now projectId source s))

    else if path |> String.endsWith ".json" then
        Decode.decodeString decodeProject content
            |> R.fold
                (\e -> ( [ "⚠️ Error in <b>" ++ path ++ "</b> ⚠️<br>" ++ decodeErrorToHtml e ], Nothing ))
                (\project -> ( [], Just project ))

    else
        ( [ "Invalid file (" ++ path ++ "), expected .sql or .json one" ], Nothing )


localSource : Time.Posix -> ProjectSourceId -> File -> ProjectSource
localSource now id file =
    ProjectSource id (lastSegment file.name) (LocalFile file.name file.size file.lastModified) now now


remoteSource : Time.Posix -> ProjectSourceId -> FileUrl -> FileContent -> ProjectSource
remoteSource now id url content =
    ProjectSource id (lastSegment url) (RemoteFile url (String.length content)) now now


lastSegment : String -> String
lastSegment path =
    path |> String.split "/" |> List.filter (\p -> not (p == "")) |> L.last |> Maybe.withDefault path
