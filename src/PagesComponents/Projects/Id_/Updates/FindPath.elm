module PagesComponents.Projects.Id_.Updates.FindPath exposing (Model, handleFindPath)

import Conf
import Dict exposing (Dict)
import Libs.Bool as B
import Libs.Maybe as M
import Libs.Nel as Nel
import Libs.Task as T
import Models.Project exposing (Project)
import Models.Project.FindPathDialog exposing (FindPathDialog)
import Models.Project.FindPathPath exposing (FindPathPath)
import Models.Project.FindPathResult exposing (FindPathResult)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.FindPathState as FindPathState exposing (FindPathState(..))
import Models.Project.FindPathStep exposing (FindPathStep)
import Models.Project.FindPathStepDir exposing (FindPathStepDir(..))
import Models.Project.Relation exposing (Relation)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (FindPathMsg(..), Msg(..))
import Ports
import Services.Lenses exposing (mapFindPathM, mapOpened, mapProjectM, mapResult, mapSettings, mapShowSettings, setFindPath, setFrom, setResult, setTo)
import Track


type alias Model x =
    { x
        | project : Maybe Project
        , findPath : Maybe FindPathDialog
    }


handleFindPath : FindPathMsg -> Model x -> ( Model x, Cmd Msg )
handleFindPath msg model =
    case msg of
        FPOpen from to ->
            ( model |> setFindPath (Just { id = Conf.ids.findPathDialog, from = from, to = to, showSettings = False, result = Empty }), Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.findPathDialog), Ports.track Track.openFindPath ] )

        FPToggleSettings ->
            ( model |> mapFindPathM (mapShowSettings not), Cmd.none )

        FPUpdateFrom from ->
            ( model |> mapFindPathM (setFrom from), Cmd.none )

        FPUpdateTo to ->
            ( model |> mapFindPathM (setTo to), Cmd.none )

        FPSearch ->
            model.findPath
                |> Maybe.andThen (\fp -> M.zip3 model.project fp.from fp.to)
                |> M.mapOrElse (\( p, from, to ) -> ( model |> mapFindPathM (setResult Searching), T.sendAfter 300 (FindPathMsg (FPCompute p.tables p.relations from to p.settings.findPath)) ))
                    ( model, Cmd.none )

        FPCompute tables relations from to settings ->
            computeFindPath tables relations from to settings |> (\result -> ( model |> mapFindPathM (setResult (Found result)), Cmd.batch [ Ports.track (Track.findPathResult result) ] ))

        FPToggleResult index ->
            ( model |> mapFindPathM (mapResult (FindPathState.map (mapOpened (\o -> B.cond (o == Just index) Nothing (Just index))))), Cmd.none )

        FPSettingsUpdate settings ->
            ( model |> mapProjectM (mapSettings (setFindPath settings)), Cmd.none )

        FPClose ->
            ( model |> setFindPath Nothing, Cmd.none )


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
