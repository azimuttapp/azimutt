module PagesComponents.Projects.Id_.Updates.Table exposing (hideAllTables, hideColumn, hideColumns, hideTable, hoverColumn, hoverNextColumn, hoverTable, showAllTables, showColumn, showColumns, showTable, showTables, sortColumns)

import Conf
import Dict exposing (Dict)
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.Task as T
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Relation as Relation
import Models.Project.Table as Table
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (Model, Msg, toastError, toastInfo)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import PagesComponents.Projects.Id_.Models.PositionHint as PositionHint exposing (PositionHint)
import Ports
import Services.Lenses exposing (mapShownTables, mapTableProps, setHoverColumn, setShownTables)
import Set


showTable : TableId -> Maybe PositionHint -> Erd -> ( Erd, Cmd Msg )
showTable id hint erd =
    case erd.tables |> Dict.get id of
        Just table ->
            if erd |> Erd.isShown id then
                ( erd, T.send (toastInfo ("Table " ++ TableId.show id ++ " already shown")) )

            else
                ( erd |> performShowTable table hint, Cmd.batch [ Ports.observeTableSize id ] )

        Nothing ->
            ( erd, T.send (toastError ("Can't show table " ++ TableId.show id ++ ": not found")) )


showTables : List TableId -> Maybe PositionHint -> Erd -> ( Erd, Cmd Msg )
showTables ids hint erd =
    ids
        |> List.indexedMap (\i id -> ( id, erd.tables |> Dict.get id, hint |> Maybe.map (PositionHint.move { left = 0, top = Conf.ui.tableHeaderHeight * toFloat i }) ))
        |> List.foldl
            (\( id, maybeTable, tableHint ) ( e, ( found, shown, notFound ) ) ->
                case maybeTable of
                    Just table ->
                        if erd |> Erd.isShown id then
                            ( e, ( found, id :: shown, notFound ) )

                        else
                            ( e |> performShowTable table tableHint, ( id :: found, shown, notFound ) )

                    Nothing ->
                        ( e, ( found, shown, id :: notFound ) )
            )
            ( erd, ( [], [], [] ) )
        |> (\( e, ( found, shown, notFound ) ) ->
                ( e
                , Cmd.batch
                    [ Ports.observeTablesSize found
                    , B.cond (shown |> List.isEmpty) Cmd.none (T.send (toastInfo ("Tables " ++ (shown |> List.map TableId.show |> String.join ", ") ++ " are already shown")))
                    , B.cond (notFound |> List.isEmpty) Cmd.none (T.send (toastInfo ("Can't show tables " ++ (notFound |> List.map TableId.show |> String.join ", ") ++ ": can't found them")))
                    ]
                )
           )


showAllTables : Erd -> ( Erd, Cmd Msg )
showAllTables erd =
    let
        tablesToInit : Dict TableId ErdTableProps
        tablesToInit =
            erd.tables |> Dict.filter (\id _ -> erd.tableProps |> Dict.notMember id) |> Dict.map (\_ -> Erd.initTable erd Nothing)

        tablesHidden : List TableId
        tablesHidden =
            erd.tables |> Dict.keys |> List.filter (\id -> (erd.tableProps |> Dict.member id) && (erd.shownTables |> List.notMember id))
    in
    ( erd |> mapTableProps (tablesToInit |> Dict.union) |> mapShownTables (\tables -> (tablesToInit |> Dict.keys) ++ tablesHidden ++ tables)
    , Cmd.batch [ Ports.observeTablesSize ((tablesToInit |> Dict.keys) ++ tablesHidden) ]
    )


hideTable : TableId -> Erd -> Erd
hideTable id erd =
    erd |> mapShownTables (List.filter (\t -> t /= id))


hideAllTables : Erd -> Erd
hideAllTables erd =
    erd |> setShownTables []


showColumn : TableId -> ColumnName -> Erd -> Erd
showColumn table column erd =
    erd |> mapTableProps (Dict.alter table (ErdTableProps.mapShownColumns (\columns -> (columns |> List.filter (\c -> c /= column)) ++ [ column ])))


hideColumn : TableId -> ColumnName -> Erd -> Erd
hideColumn table column erd =
    erd |> mapTableProps (Dict.alter table (ErdTableProps.mapShownColumns (List.filter (\c -> c /= column))))


hoverNextColumn : TableId -> ColumnName -> Model -> Model
hoverNextColumn table column model =
    let
        nextColumn : Maybe ColumnName
        nextColumn =
            model.erd
                |> Maybe.andThen (\e -> e.tableProps |> Dict.get table)
                |> Maybe.andThen (\p -> p.shownColumns |> List.dropUntil (\c -> c == column) |> List.drop 1 |> List.head)
    in
    model |> setHoverColumn (nextColumn |> Maybe.map (ColumnRef table))


showColumns : TableId -> String -> Erd -> Erd
showColumns id kind erd =
    updateColumns id
        (\table columns ->
            erd.relations
                |> Relation.withTableLink id
                |> (\tableRelations ->
                        columns
                            ++ (table.columns
                                    |> Ned.values
                                    |> Nel.filter (\c -> columns |> List.notMember c.name)
                                    |> List.filter
                                        (\column ->
                                            case kind of
                                                "all" ->
                                                    True

                                                "relations" ->
                                                    tableRelations |> Relation.withLink id column.name |> List.nonEmpty

                                                _ ->
                                                    False
                                        )
                                    |> List.map .name
                               )
                   )
        )
        erd


hideColumns : TableId -> String -> Erd -> Erd
hideColumns id kind erd =
    updateColumns id
        (\table columns ->
            erd.relations
                |> Relation.withTableLink id
                |> (\tableRelations ->
                        columns
                            |> List.zipWith (\name -> table.columns |> Ned.get name)
                            |> List.filter
                                (\( name, col ) ->
                                    case ( kind, col ) of
                                        ( "relations", Just _ ) ->
                                            tableRelations |> Relation.withLink id name |> List.nonEmpty

                                        ( "regular", Just _ ) ->
                                            (name |> Table.inPrimaryKey table |> Maybe.isJust)
                                                || (tableRelations |> Relation.withLink id name |> List.nonEmpty)
                                                || (name |> Table.inUniques table |> List.nonEmpty)
                                                || (name |> Table.inIndexes table |> List.nonEmpty)

                                        ( "nullable", Just c ) ->
                                            not c.nullable

                                        ( "all", _ ) ->
                                            False

                                        _ ->
                                            False
                                )
                            |> List.map Tuple.first
                   )
        )
        erd


sortColumns : TableId -> ColumnOrder -> Erd -> Erd
sortColumns id kind erd =
    updateColumns id
        (\table columns ->
            columns
                |> List.filterMap (\name -> table.columns |> Ned.get name)
                |> ColumnOrder.sortBy kind table erd.relations
                |> List.map .name
        )
        erd


hoverTable : TableId -> Bool -> Dict TableId ErdTableProps -> Dict TableId ErdTableProps
hoverTable table enter props =
    props
        |> Dict.map
            (\id p ->
                if id == table && p.isHover /= enter then
                    p |> ErdTableProps.setHover enter

                else if id /= table && p.isHover then
                    p |> ErdTableProps.setHover False

                else
                    p
            )


hoverColumn : ColumnRef -> Bool -> Erd -> Dict TableId ErdTableProps -> Dict TableId ErdTableProps
hoverColumn column enter erd props =
    props
        |> Dict.map
            (\id p ->
                (if enter then
                    (erd.tables |> Dict.get id)
                        |> (\table ->
                                p.shownColumns
                                    |> List.filter (\c -> (column.table == id && column.column == c) || (getRelations table c |> List.any (isSame column)))
                                    |> Set.fromList
                           )

                 else
                    Set.empty
                )
                    |> (\highlightedColumns -> p |> ErdTableProps.setHighlightedColumns highlightedColumns)
            )


getRelations : Maybe ErdTable -> ColumnName -> List ErdColumnRef
getRelations table name =
    table |> Maybe.andThen (\t -> t.columns |> Ned.get name) |> Maybe.mapOrElse (\c -> c.outRelations ++ c.inRelations) []


isSame : ColumnRef -> ErdColumnRef -> Bool
isSame ref erdRef =
    ref.table == erdRef.table && ref.column == erdRef.column


performShowTable : ErdTable -> Maybe PositionHint -> Erd -> Erd
performShowTable table hint erd =
    erd
        |> mapTableProps (Dict.update table.id (Maybe.orElse (Just (table |> Erd.initTable erd hint))))
        |> mapShownTables (\t -> B.cond (t |> List.member table.id) t (table.id :: t))


updateColumns : TableId -> (ErdTable -> List ColumnName -> List ColumnName) -> Erd -> Erd
updateColumns id update erd =
    erd.tables
        |> Dict.get id
        |> Maybe.mapOrElse (\table -> erd |> mapTableProps (Dict.alter id (ErdTableProps.mapShownColumns (update table)))) erd
