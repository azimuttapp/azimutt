module PagesComponents.Projects.Id_.Updates.Table exposing (hideColumn, hideColumns, hideTable, hoverColumn, hoverNextColumn, hoverTable, mapTablePropOrSelected, showAllTables, showColumn, showColumns, showTable, showTables, sortColumns)

import Conf
import Dict exposing (Dict)
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Relation as Relation
import Models.Project.Table as Table
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (Model, Msg(..))
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import PagesComponents.Projects.Id_.Models.PositionHint as PositionHint exposing (PositionHint)
import Ports
import Services.Lenses exposing (mapRelatedTables, mapShown, mapShownTables, mapTableProps, mapTablePropsCmd, setHoverColumn)
import Services.Toasts as Toasts
import Set


showTable : TableId -> Maybe PositionHint -> Erd -> ( Erd, Cmd Msg )
showTable id hint erd =
    case erd.tables |> Dict.get id of
        Just table ->
            if erd |> Erd.isShown id then
                ( erd, Toasts.info Toast ("Table " ++ TableId.show id ++ " already shown") )

            else
                ( erd |> performShowTable table hint, Cmd.batch [ Ports.observeTableSize id ] )

        Nothing ->
            ( erd, Toasts.error Toast ("Can't show table " ++ TableId.show id ++ ": not found") )


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
                    , B.cond (shown |> List.isEmpty) Cmd.none (Toasts.info Toast ("Tables " ++ (shown |> List.map TableId.show |> String.join ", ") ++ " are already shown"))
                    , B.cond (notFound |> List.isEmpty) Cmd.none (Toasts.info Toast ("Can't show tables " ++ (notFound |> List.map TableId.show |> String.join ", ") ++ ": can't found them"))
                    ]
                )
           )


showAllTables : Erd -> ( Erd, Cmd Msg )
showAllTables erd =
    let
        tablesToInit : Dict TableId ErdTableProps
        tablesToInit =
            erd.tables |> Dict.filter (\id _ -> erd.tableProps |> Dict.notMember id) |> Dict.map (\_ -> ErdTableProps.init erd.settings erd.relations erd.shownTables Nothing erd.notes)

        tablesHidden : List TableId
        tablesHidden =
            erd.tables |> Dict.keys |> List.filter (\id -> (erd.tableProps |> Dict.member id) && (erd.shownTables |> List.notMember id))
    in
    ( erd
        |> mapTableProps (tablesToInit |> Dict.union)
        |> mapTableProps (Dict.map (\_ -> mapRelatedTables (Dict.map (\_ -> mapShown (\_ -> True)))))
        |> mapShownTables (\tables -> (tablesToInit |> Dict.keys) ++ tablesHidden ++ tables)
    , Cmd.batch [ Ports.observeTablesSize ((tablesToInit |> Dict.keys) ++ tablesHidden) ]
    )


hideTable : TableId -> Erd -> Erd
hideTable id erd =
    if erd.tableProps |> Dict.get id |> Maybe.map .selected |> Maybe.withDefault False then
        erd.tableProps |> Dict.values |> List.filter .selected |> List.foldl (\p -> hideTableReal p.id) erd

    else
        hideTableReal id erd


hideTableReal : TableId -> Erd -> Erd
hideTableReal id erd =
    erd
        |> mapTableProps (Dict.map (\_ -> mapRelatedTables (Dict.alter id (mapShown (\_ -> False)))))
        |> mapShownTables (List.filter (\t -> t /= id))


showColumn : TableId -> ColumnName -> Erd -> Erd
showColumn table column erd =
    erd |> mapTableProps (Dict.alter table (ErdTableProps.mapShownColumns (\columns -> (columns |> List.filter (\c -> c /= column)) ++ [ column ]) erd.notes))


hideColumn : TableId -> ColumnName -> Erd -> Erd
hideColumn table column erd =
    erd |> mapTableProps (Dict.alter table (ErdTableProps.mapShownColumns (List.filter (\c -> c /= column)) erd.notes))


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


showColumns : TableId -> String -> Erd -> ( Erd, Cmd Msg )
showColumns id kind erd =
    mapTablePropsOrSelectedColumns id
        (\table columns ->
            erd.relations
                |> Relation.withTableLink id
                |> (\tableRelations ->
                        columns
                            ++ (table.columns
                                    |> Dict.values
                                    |> List.filter (\c -> columns |> List.notMember c.name)
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


hideColumns : TableId -> String -> Erd -> ( Erd, Cmd Msg )
hideColumns id kind erd =
    mapTablePropsOrSelectedColumns id
        (\table columns ->
            erd.relations
                |> Relation.withTableLink id
                |> (\tableRelations ->
                        columns
                            |> List.zipWith (\name -> table.columns |> Dict.get name)
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


sortColumns : TableId -> ColumnOrder -> Erd -> ( Erd, Cmd Msg )
sortColumns id kind erd =
    mapTablePropsOrSelectedColumns id
        (\table columns ->
            columns
                |> List.filterMap (\name -> table.columns |> Dict.get name)
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
                                    |> List.filter
                                        (\c ->
                                            (column.table == id && column.column == c)
                                                -- || (column.table == id && (table |> Maybe.andThen (.columns >> Ned.get c) |> Maybe.any (\col -> List.nonEmpty col.inRelations || List.nonEmpty col.outRelations)))
                                                || (getRelations table c |> List.any (\r -> r.table == column.table && r.column == column.column))
                                        )
                                    |> Set.fromList
                           )

                 else
                    Set.empty
                )
                    |> (\highlightedColumns -> p |> ErdTableProps.setHighlightedColumns highlightedColumns)
            )


mapTablePropOrSelected : TableId -> (ErdTableProps -> ErdTableProps) -> Dict TableId ErdTableProps -> ( Dict TableId ErdTableProps, Cmd Msg )
mapTablePropOrSelected id transform props =
    props
        |> Dict.get id
        |> Maybe.map
            (\prop ->
                if prop.selected then
                    ( props
                        |> Dict.map
                            (\_ p ->
                                if p.selected then
                                    transform p

                                else
                                    p
                            )
                    , Cmd.none
                    )

                else
                    ( props |> Dict.alter id transform, Cmd.none )
            )
        |> Maybe.withDefault ( props, Toasts.info Toast ("Table " ++ TableId.show id ++ " not found") )


getRelations : Maybe ErdTable -> ColumnName -> List ErdColumnRef
getRelations table name =
    table |> Maybe.andThen (\t -> t.columns |> Dict.get name) |> Maybe.mapOrElse (\c -> c.outRelations ++ c.inRelations) []


performShowTable : ErdTable -> Maybe PositionHint -> Erd -> Erd
performShowTable table hint erd =
    erd
        |> mapTableProps (Dict.update table.id (Maybe.orElse (Just (ErdTableProps.init erd.settings erd.relations erd.shownTables hint erd.notes table))))
        |> mapTableProps (Dict.map (\_ -> mapRelatedTables (Dict.update table.id (Maybe.map (mapShown (\_ -> True))))))
        |> mapShownTables (\t -> B.cond (t |> List.member table.id) t (table.id :: t))


mapTablePropsOrSelectedColumns : TableId -> (ErdTable -> List ColumnName -> List ColumnName) -> Erd -> ( Erd, Cmd Msg )
mapTablePropsOrSelectedColumns id transform erd =
    erd
        |> mapTablePropsCmd
            (mapTablePropOrSelected id
                (\p ->
                    p
                        |> ErdTableProps.mapShownColumns
                            (\cols ->
                                erd.tables
                                    |> Dict.get p.id
                                    |> Maybe.map (\table -> transform table cols)
                                    |> Maybe.withDefault cols
                            )
                            erd.notes
                )
            )
