module PagesComponents.Projects.Id_.Updates.FindPath exposing (Model, computeFindPath, handleFindPath)

import Conf
import Dict exposing (Dict)
import Libs.Bool as B
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel as Nel
import Libs.Task as T
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.ProjectSettings as ProjectSettings
import Models.Project.TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (FindPathMsg(..), Msg(..))
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.FindPathDialog exposing (FindPathDialog)
import PagesComponents.Projects.Id_.Models.FindPathPath exposing (FindPathPath)
import PagesComponents.Projects.Id_.Models.FindPathResult exposing (FindPathResult)
import PagesComponents.Projects.Id_.Models.FindPathState as FindPathState exposing (FindPathState(..))
import PagesComponents.Projects.Id_.Models.FindPathStep exposing (FindPathStep)
import PagesComponents.Projects.Id_.Models.FindPathStepDir exposing (FindPathStepDir(..))
import Ports
import Services.Lenses exposing (mapErdM, mapFindPathM, mapOpened, mapResult, mapSettings, mapShowSettings, setFindPath, setFrom, setResult, setTo)
import Track


type alias Model x =
    { x
        | erd : Maybe Erd
        , findPath : Maybe FindPathDialog
    }


handleFindPath : FindPathMsg -> Model x -> ( Model x, Cmd Msg )
handleFindPath msg model =
    case msg of
        FPOpen from to ->
            ( model
                |> setFindPath (Just { id = Conf.ids.findPathDialog, from = from, to = to, showSettings = False, result = Empty })
                |> mapErdM (mapSettings ProjectSettings.fillFindPath)
            , Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.findPathDialog), Ports.track Track.openFindPath ]
            )

        FPToggleSettings ->
            ( model |> mapFindPathM (mapShowSettings not), Cmd.none )

        FPUpdateFrom from ->
            ( model |> mapFindPathM (setFrom from), Cmd.none )

        FPUpdateTo to ->
            ( model |> mapFindPathM (setTo to), Cmd.none )

        FPSearch ->
            model.findPath
                |> Maybe.andThen (\fp -> Maybe.zip3 model.erd fp.from fp.to)
                |> Maybe.mapOrElse (\( e, from, to ) -> ( model |> mapFindPathM (setResult Searching), T.sendAfter 300 (FindPathMsg (FPCompute e.tables e.relations from to e.settings.findPath)) ))
                    ( model, Cmd.none )

        FPCompute tables relations from to settings ->
            computeFindPath tables relations from to settings |> (\result -> ( model |> mapFindPathM (setResult (Found result)), Cmd.batch [ Ports.track (Track.findPathResult result) ] ))

        FPToggleResult index ->
            ( model |> mapFindPathM (mapResult (FindPathState.map (mapOpened (\o -> B.cond (o == Just index) Nothing (Just index))))), Cmd.none )

        FPSettingsUpdate settings ->
            ( model |> mapErdM (mapSettings (setFindPath settings)), Cmd.none )

        FPClose ->
            ( model |> setFindPath Nothing, Cmd.none )


computeFindPath : Dict TableId ErdTable -> List ErdRelation -> TableId -> TableId -> FindPathSettings -> FindPathResult
computeFindPath tables relations from to settings =
    { from = from, to = to, paths = buildPaths tables (filterRelations settings relations) settings from (\t -> t.id == to) [], opened = Nothing, settings = settings }


filterRelations : FindPathSettings -> List ErdRelation -> List ErdRelation
filterRelations settings relations =
    -- hack to keep computing low
    let
        removeTable : TableId -> Bool
        removeTable =
            ProjectSettings.removeTable settings.ignoredTables

        removeColumn : ColumnName -> Bool
        removeColumn =
            ProjectSettings.removeColumn settings.ignoredColumns
    in
    relations |> List.filterNot (\r -> removeTable r.src.table || removeTable r.ref.table || removeColumn r.src.column || removeColumn r.ref.column)


buildPaths : Dict TableId ErdTable -> List ErdRelation -> FindPathSettings -> TableId -> (ErdTable -> Bool) -> List FindPathStep -> List FindPathPath
buildPaths tables relations settings tableId isDone curPath =
    -- FIXME improve algo complexity
    tables
        |> Dict.get tableId
        |> Maybe.mapOrElse
            (\table ->
                if isDone table then
                    curPath |> Nel.fromList |> Maybe.mapOrElse (\p -> [ p ]) []

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
