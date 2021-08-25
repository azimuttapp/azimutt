module PagesComponents.App.Updates.FindPath exposing (computeFindPath)

import Dict exposing (Dict)
import Libs.Nel as Nel
import Models.Project exposing (FindPathPath, FindPathResult, FindPathSettings, FindPathStep, FindPathStepDir(..), Relation, Table, TableId)


computeFindPath : Dict TableId Table -> List Relation -> TableId -> TableId -> FindPathSettings -> FindPathResult
computeFindPath tables relations from to settings =
    { from = from, to = to, paths = buildPaths tables (filterRelations settings relations) settings from (\t -> t.id == to) [], settings = settings }


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
        |> Maybe.map
            (\table ->
                if isDone table then
                    curPath |> Nel.fromList |> Maybe.map (\p -> [ p ]) |> Maybe.withDefault []

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
        |> Maybe.withDefault []
