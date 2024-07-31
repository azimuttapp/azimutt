module PagesComponents.Organization_.Project_.Updates.FindPath exposing (Model, computeFindPath, handleFindPath)

import Conf
import Dict exposing (Dict)
import Libs.Bool as B
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel as Nel
import Libs.Task as T
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.ProjectSettings as ProjectSettings
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models exposing (FindPathMsg(..), Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.FindPathDialog exposing (FindPathDialog)
import PagesComponents.Organization_.Project_.Models.FindPathPath exposing (FindPathPath)
import PagesComponents.Organization_.Project_.Models.FindPathResult exposing (FindPathResult)
import PagesComponents.Organization_.Project_.Models.FindPathState as FindPathState exposing (FindPathState(..))
import PagesComponents.Organization_.Project_.Models.FindPathStep exposing (FindPathStep)
import PagesComponents.Organization_.Project_.Models.FindPathStepDir exposing (FindPathStepDir(..))
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import Services.Lenses exposing (mapErdM, mapFindPathM, mapOpened, mapResult, mapSettings, mapShowSettings, setFindPath, setFrom, setResult, setTo)
import Track


type alias Model x =
    { x
        | conf : ErdConf
        , dirty : Bool
        , erd : Maybe Erd
        , findPath : Maybe FindPathDialog
    }


handleFindPath : FindPathMsg -> Model x -> ( Model x, Extra Msg )
handleFindPath msg model =
    case msg of
        FPOpen from to ->
            ( model
                |> setFindPath
                    (Just
                        { id = Conf.ids.findPathDialog
                        , from = from |> Maybe.map (TableId.show (model.erd |> Erd.defaultSchemaM)) |> Maybe.withDefault ""
                        , to = to |> Maybe.map (TableId.show (model.erd |> Erd.defaultSchemaM)) |> Maybe.withDefault ""
                        , showSettings = False
                        , result = Empty
                        }
                    )
                |> mapErdM (mapSettings ProjectSettings.fillFindPath)
            , Extra.cmdL [ T.sendAfter 1 (ModalOpen Conf.ids.findPathDialog), Track.findPathOpened model.erd ]
            )

        FPToggleSettings ->
            ( model |> mapFindPathM (mapShowSettings not), Extra.none )

        FPUpdateFrom from ->
            ( model |> mapFindPathM (setFrom from >> setResult Empty), Extra.none )

        FPUpdateTo to ->
            ( model |> mapFindPathM (setTo to >> setResult Empty), Extra.none )

        FPSearch ->
            Maybe.zip model.findPath model.erd
                |> Maybe.andThen (\( fp, erd ) -> Maybe.zip3 (Just erd) (erd |> Erd.getTableI (TableId.parse fp.from)) (erd |> Erd.getTableI (TableId.parse fp.to)))
                |> Maybe.map (\( erd, from, to ) -> ( model |> mapFindPathM (setResult Searching), FindPathMsg (FPCompute erd.tables erd.relations from.id to.id erd.settings.findPath) |> T.sendAfter 300 |> Extra.cmd ))
                |> Maybe.withDefault ( model, Extra.none )

        FPCompute tables relations from to settings ->
            computeFindPath tables relations from to settings |> (\result -> ( model |> mapFindPathM (setResult (Found result)), Track.findPathResults model.erd result |> Extra.cmd ))

        FPToggleResult index ->
            ( model |> mapFindPathM (mapResult (FindPathState.map (mapOpened (\o -> B.cond (o == Just index) Nothing (Just index))))), Extra.none )

        FPSettingsUpdate settings ->
            ( model |> mapErdM (mapSettings (setFindPath settings)), Extra.none )

        FPClose ->
            ( model |> setFindPath Nothing, Extra.none )


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

        removeColumn : ColumnPath -> Bool
        removeColumn =
            ProjectSettings.removeColumn settings.ignoredColumns
    in
    relations |> List.filterNot (\r -> removeTable r.src.table || removeTable r.ref.table || removeColumn r.src.column || removeColumn r.ref.column)


buildPaths : Dict TableId ErdTable -> List ErdRelation -> FindPathSettings -> TableId -> (ErdTable -> Bool) -> List FindPathStep -> List FindPathPath
buildPaths tables relations settings tableId isDone curPath =
    -- TODO: improve algo complexity
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
