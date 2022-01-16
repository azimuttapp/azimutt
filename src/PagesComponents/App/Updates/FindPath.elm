module PagesComponents.App.Updates.FindPath exposing (computeFindPath, handleFindPath)

import Conf
import Dict exposing (Dict)
import Libs.Maybe as M
import Libs.Nel as Nel
import Libs.Task exposing (sendAfter)
import Models.Project.FindPathDialog exposing (FindPathDialog)
import Models.Project.FindPathPath exposing (FindPathPath)
import Models.Project.FindPathResult exposing (FindPathResult)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.FindPathState exposing (FindPathState(..))
import Models.Project.FindPathStep exposing (FindPathStep)
import Models.Project.FindPathStepDir exposing (FindPathStepDir(..))
import Models.Project.ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import PagesComponents.App.Models exposing (FindPathMsg(..), Model, Msg(..))
import Ports exposing (activateTooltipsAndPopovers, showModal, track)
import Services.Lenses exposing (setProject, setSettings)
import Track


type alias Model x y =
    { x
        | findPath : Maybe FindPathDialog
        , project :
            Maybe
                { y
                    | tables : Dict TableId Table
                    , relations : List Relation
                    , settings : ProjectSettings
                }
    }


handleFindPath : FindPathMsg -> Model x y -> ( Model x y, Cmd Msg )
handleFindPath msg model =
    case msg of
        FPInit from to ->
            ( { model | findPath = Just { id = Conf.ids.findPathDialog, from = from, to = to, showSettings = False, result = Empty } }, Cmd.batch [ showModal Conf.ids.findPathDialog, track Track.openFindPath ] )

        FPUpdateFrom from ->
            ( { model | findPath = model.findPath |> Maybe.map (\m -> { m | from = from }) }, Cmd.none )

        FPUpdateTo to ->
            ( { model | findPath = model.findPath |> Maybe.map (\m -> { m | to = to }) }, Cmd.none )

        FPSearch ->
            model.findPath
                |> Maybe.andThen (\fp -> Maybe.map3 (\p from to -> ( p, from, to )) model.project fp.from fp.to)
                |> M.mapOrElse (\( p, from, to ) -> ( { model | findPath = model.findPath |> Maybe.map (\m -> { m | result = Searching }) }, sendAfter 300 (FindPathMsg (FPCompute p.tables p.relations from to p.settings.findPath)) ))
                    ( model, Cmd.none )

        FPCompute tables relations from to settings ->
            computeFindPath tables relations from to settings |> (\result -> ( { model | findPath = model.findPath |> Maybe.map (\m -> { m | result = Found result }) }, Cmd.batch [ activateTooltipsAndPopovers, track (Track.findPathResult result) ] ))

        FPSettingsUpdate settings ->
            ( model |> setProject (setSettings (\s -> { s | findPath = settings })), Cmd.none )


computeFindPath : Dict TableId Table -> List Relation -> TableId -> TableId -> FindPathSettings -> FindPathResult
computeFindPath tables relations from to settings =
    { from = from, to = to, paths = buildPaths tables (filterRelations settings relations) settings from (\t -> t.id == to) [], opened = Nothing, settings = settings }


filterRelations : FindPathSettings -> List Relation -> List Relation
filterRelations settings relations =
    -- ugly hack to keep computing low
    relations
        |> List.filter
            (\r ->
                not
                    (List.member r.src.table settings.ignoredTables
                        || List.member r.ref.table settings.ignoredTables
                        || List.member r.src.column settings.ignoredColumns
                        || List.member r.ref.column settings.ignoredColumns
                    )
            )


buildPaths : Dict TableId Table -> List Relation -> FindPathSettings -> TableId -> (Table -> Bool) -> List FindPathStep -> List FindPathPath
buildPaths tables relations settings tableId isDone curPath =
    -- FIXME improve algo complexity
    tables
        |> Dict.get tableId
        |> M.mapOrElse
            (\table ->
                if isDone table then
                    curPath |> Nel.fromList |> M.mapOrElse (\p -> [ p ]) []

                else
                    relations
                        |> List.partition (\r -> r.src.table == tableId || r.ref.table == tableId)
                        |> (\( tableRelations, otherRelations ) ->
                                if (tableRelations |> List.isEmpty) || ((curPath |> List.length) > settings.maxPathLength) then
                                    []

                                else
                                    tableRelations
                                        |> List.concatMap
                                            (\r ->
                                                if r.src.table == tableId then
                                                    buildPaths (tables |> Dict.remove tableId) otherRelations settings r.ref.table isDone (curPath ++ [ { relation = r, direction = Right } ])

                                                else
                                                    buildPaths (tables |> Dict.remove tableId) otherRelations settings r.src.table isDone (curPath ++ [ { relation = r, direction = Left } ])
                                            )
                           )
            )
            []
