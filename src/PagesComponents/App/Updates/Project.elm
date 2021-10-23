module PagesComponents.App.Updates.Project exposing (addToProject, createProject, deleteProject, useProject)

import Conf exposing (conf)
import DataSources.SqlParser.FileParser exposing (parseSchema)
import DataSources.SqlParser.ProjectAdapter exposing (buildProjectFromSql, buildSchema)
import Dict
import Json.Decode as Decode
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (FileContent, TrackEvent)
import Libs.Nel as Nel
import Libs.Result as R
import Libs.String as S
import Libs.Task as T
import Models.Project exposing (Project, ProjectId, ProjectName, ProjectSource, ProjectSourceContent(..), Relation, SampleName, Schema, Table, decodeProject, extractPath)
import PagesComponents.App.Models exposing (Errors, Model, Msg(..), initSwitch)
import PagesComponents.App.Updates.Helpers exposing (decodeErrorToHtml)
import Ports exposing (activateTooltipsAndPopovers, click, dropProject, hideModal, hideOffcanvas, observeTablesSize, saveProject, toastError, toastInfo, track, trackError)
import Time
import Tracking exposing (events)


createProject : Time.Posix -> ProjectId -> ProjectSource -> FileContent -> Maybe SampleName -> Model -> ( Model, Cmd Msg )
createProject now projectId source content sample model =
    buildProject (model.storedProjects |> List.map .name) now projectId source content sample |> loadProject events.createProject model


addToProject : Time.Posix -> ProjectSource -> FileContent -> Project -> ( Project, Cmd Msg )
addToProject now source content project =
    let
        path : String
        path =
            extractPath source.source
    in
    if path |> String.endsWith ".sql" then
        case
            parseSchema path content
                |> Tuple.mapSecond (buildSchema now)
                |> Tuple.mapSecond (\schema -> ( project |> addSource source schema now, events.addSource schema ))
        of
            ( errors, ( updatedProject, event ) ) ->
                ( updatedProject
                , Cmd.batch
                    ((errors |> List.map toastError)
                        ++ (errors |> List.map (trackError "parse-schema"))
                        ++ [ toastInfo ("<b>" ++ source.name ++ "</b> loaded.")
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
                                   , track (projectEvent p)
                                   ]
                        )
                    |> Maybe.withDefault []
               )
        )
    )


buildProject : List ProjectName -> Time.Posix -> ProjectId -> ProjectSource -> FileContent -> Maybe SampleName -> ( Errors, Maybe Project )
buildProject takenNames now projectId source content sample =
    let
        path : String
        path =
            extractPath source.source
    in
    if path |> String.endsWith ".sql" then
        parseSchema path content |> Tuple.mapSecond (\s -> Just (buildProjectFromSql takenNames now projectId source s sample))

    else if path |> String.endsWith ".json" then
        Decode.decodeString decodeProject content
            |> R.fold
                (\e -> ( [ "⚠️ Error in <b>" ++ path ++ "</b> ⚠️<br>" ++ decodeErrorToHtml e ], Nothing ))
                (\p -> ( [], Just { p | id = projectId, name = S.unique takenNames p.name, createdAt = now, updatedAt = now, fromSample = sample } ))

    else
        ( [ "Invalid file (" ++ path ++ "), expected .sql or .json one" ], Nothing )


addSource : ProjectSource -> Schema -> Time.Posix -> Project -> Project
addSource source schema now project =
    { project
        | sources = project.sources |> Nel.append source
        , schema = mergeSchema project.schema schema
        , updatedAt = now
    }


mergeSchema : Schema -> Schema -> Schema
mergeSchema s1 s2 =
    { s1
        | tables = Dict.merge Dict.insert (\id t1 t2 acc -> Dict.insert id (mergeTable t1 t2) acc) Dict.insert s1.tables s2.tables Dict.empty
        , relations =
            (s1.relations |> List.map (\r1 -> s2.relations |> L.find (sameRelation r1) |> Maybe.map (mergeRelation r1) |> Maybe.withDefault r1))
                ++ (s2.relations |> L.filterNot (\r2 -> s1.relations |> List.any (sameRelation r2)))
    }


mergeTable : Table -> Table -> Table
mergeTable t1 t2 =
    { t1 | sources = t1.sources ++ t2.sources }


sameRelation : Relation -> Relation -> Bool
sameRelation r1 r2 =
    r1.name == r2.name


mergeRelation : Relation -> Relation -> Relation
mergeRelation r1 r2 =
    { r1 | sources = r1.sources ++ r2.sources }
