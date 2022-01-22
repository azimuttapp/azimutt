module PagesComponents.Projects.Id_.Updates.Table exposing (hideAllTables, hideColumn, hideColumns, hideTable, hoverColumn, hoverNextColumn, hoverTable, showAllTables, showColumn, showColumns, showTable, showTables, sortColumns)

import Dict exposing (Dict)
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.Task as T
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.Project exposing (Project)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Layout exposing (Layout)
import Models.Project.Relation as Relation
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (Model, Msg, toastError, toastInfo)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import Ports
import Services.Lenses exposing (mapColumns, mapLayout, mapShownTables, mapTableProps, mapTables, setHiddenTables, setHoverColumn, setTables)
import Set


showTable : TableId -> Erd -> ( Erd, Cmd Msg )
showTable id erd =
    case erd.tables |> Dict.get id of
        Just table ->
            if erd |> Erd.isShown id then
                ( erd, T.send (toastInfo ("Table " ++ TableId.show id ++ " already shown")) )

            else
                ( erd |> performShowTable table, Cmd.batch [ Ports.observeTableSize id ] )

        Nothing ->
            ( erd, T.send (toastError ("Can't show table " ++ TableId.show id ++ ": not found")) )


showTables : List TableId -> Erd -> ( Erd, Cmd Msg )
showTables ids erd =
    ids
        |> List.zipWith (\id -> erd.tables |> Dict.get id)
        |> List.foldr
            (\( id, maybeTable ) ( e, ( found, shown, notFound ) ) ->
                case maybeTable of
                    Just table ->
                        if erd |> Erd.isShown id then
                            ( e, ( found, id :: shown, notFound ) )

                        else
                            ( e |> performShowTable table, ( id :: found, shown, notFound ) )

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
            erd.tables |> Dict.filter (\id _ -> erd.tableProps |> Dict.notMember id) |> Dict.map (\_ t -> erd |> Erd.initTable t)

        tablesHidden : List TableId
        tablesHidden =
            erd.tables |> Dict.keys |> List.filter (\id -> (erd.tableProps |> Dict.member id) && (erd.shownTables |> List.notMember id))
    in
    ( erd |> mapTableProps (tablesToInit |> Dict.union) |> mapShownTables (\tables -> (tablesToInit |> Dict.keys) ++ tablesHidden ++ tables)
    , Cmd.batch [ Ports.observeTablesSize ((tablesToInit |> Dict.keys) ++ tablesHidden) ]
    )


hideTable : TableId -> Layout -> Layout
hideTable id layout =
    layout
        |> mapTables (List.filter (\t -> not (t.id == id)))
        |> setHiddenTables (((layout.tables |> List.findBy .id id |> Maybe.toList) ++ layout.hiddenTables) |> List.uniqueBy .id)


hideAllTables : Layout -> Layout
hideAllTables layout =
    layout |> setTables [] |> setHiddenTables ((layout.tables ++ layout.hiddenTables) |> List.uniqueBy .id)


showColumn : TableId -> ColumnName -> Layout -> Layout
showColumn table column layout =
    layout |> mapTables (List.updateBy .id table (mapColumns (\columns -> columns |> List.addAt column (columns |> List.length))))


hideColumn : TableId -> ColumnName -> Layout -> Layout
hideColumn table column layout =
    layout |> mapTables (List.updateBy .id table (mapColumns (List.filter (\c -> not (c == column)))))


hoverNextColumn : TableId -> ColumnName -> Model -> Model
hoverNextColumn table column model =
    let
        nextColumn : Maybe ColumnName
        nextColumn =
            model.project
                |> Maybe.andThen (\p -> p.layout.tables |> List.findBy .id table)
                |> Maybe.andThen (\t -> t.columns |> List.dropUntil (\c -> c == column) |> List.drop 1 |> List.head)
    in
    model |> setHoverColumn (nextColumn |> Maybe.map (ColumnRef table))


showColumns : TableId -> String -> Project -> Project
showColumns id kind project =
    updateColumns id
        (\table columns ->
            project.relations
                |> Relation.withTableLink id
                |> (\tableRelations ->
                        columns
                            ++ (table.columns
                                    |> Ned.values
                                    |> Nel.filter (\c -> not (columns |> List.member c.name))
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
        project


hideColumns : TableId -> String -> Project -> Project
hideColumns id kind project =
    updateColumns id
        (\table columns ->
            project.relations
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
        project


sortColumns : TableId -> ColumnOrder -> Project -> Project
sortColumns id kind project =
    updateColumns id
        (\table columns ->
            columns
                |> List.filterMap (\name -> table.columns |> Ned.get name)
                |> ColumnOrder.sortBy kind table project.relations
                |> List.map .name
        )
        project


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


performShowTable : ErdTable -> Erd -> Erd
performShowTable table erd =
    erd
        |> mapTableProps (Dict.update table.id (Maybe.orElse (Just (erd |> Erd.initTable table))))
        |> mapShownTables (\t -> B.cond (t |> List.member table.id) t (table.id :: t))


updateColumns : TableId -> (Table -> List ColumnName -> List ColumnName) -> Project -> Project
updateColumns id update project =
    project.tables
        |> Dict.get id
        |> Maybe.mapOrElse (\table -> project |> mapLayout (mapTables (\tables -> tables |> List.updateBy .id id (mapColumns (update table))))) project
