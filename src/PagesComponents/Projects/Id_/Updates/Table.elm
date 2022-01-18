module PagesComponents.Projects.Id_.Updates.Table exposing (hideAllTables, hideColumn, hideColumns, hideTable, hoverColumn, hoverNextColumn, hoverTable, showAllTables, showColumn, showColumns, showTable, showTables, sortColumns)

import Dict exposing (Dict)
import Libs.Bool as B
import Libs.List as L
import Libs.Maybe as M
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
import Models.Project.TableProps as TableProps exposing (TableProps)
import PagesComponents.Projects.Id_.Models exposing (Model, Msg, toastError, toastInfo)
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd, ErdColumnRelation, ErdTable, ErdTableProps)
import Ports
import Services.Lenses exposing (setLayout)
import Set


showTable : TableId -> Project -> ( Project, Cmd Msg )
showTable id project =
    case project.tables |> Dict.get id of
        Just table ->
            if project.layout.tables |> L.memberBy .id id then
                ( project, T.send (toastInfo ("Table " ++ TableId.show id ++ " already shown")) )

            else
                ( project |> performShowTable table, Cmd.batch [ Ports.observeTableSize id ] )

        Nothing ->
            ( project, T.send (toastError ("Can't show table " ++ TableId.show id ++ ": not found")) )


showTables : List TableId -> Project -> ( Project, Cmd Msg )
showTables ids project =
    ids
        |> L.zipWith (\id -> project.tables |> Dict.get id)
        |> List.foldr
            (\( id, maybeTable ) ( p, ( found, shown, notFound ) ) ->
                case maybeTable of
                    Just table ->
                        if project.layout.tables |> L.memberBy .id id then
                            ( p, ( found, id :: shown, notFound ) )

                        else
                            ( p |> performShowTable table, ( id :: found, shown, notFound ) )

                    Nothing ->
                        ( p, ( found, shown, id :: notFound ) )
            )
            ( project, ( [], [], [] ) )
        |> (\( p, ( found, shown, notFound ) ) ->
                ( p
                , Cmd.batch
                    (B.cond (found |> List.isEmpty) [] [ Ports.observeTablesSize found ]
                        ++ B.cond (shown |> List.isEmpty) [] [ T.send (toastInfo ("Tables " ++ (shown |> List.map TableId.show |> String.join ", ") ++ " are already shown")) ]
                        ++ B.cond (notFound |> List.isEmpty) [] [ T.send (toastInfo ("Can't show tables " ++ (notFound |> List.map TableId.show |> String.join ", ") ++ ": can't found them")) ]
                    )
                )
           )


showAllTables : Project -> ( Project, Cmd Msg )
showAllTables project =
    let
        initProps : Layout -> List TableProps
        initProps =
            \l ->
                project.tables
                    |> Dict.values
                    |> List.filter (\t -> not ((l.tables |> L.memberBy .id t.id) && (l.hiddenTables |> L.memberBy .id t.id)))
                    |> List.map (TableProps.init project.settings project.relations)
    in
    ( project |> setLayout (\l -> { l | tables = (l.tables ++ l.hiddenTables ++ initProps l) |> L.uniqueBy .id, hiddenTables = [] })
    , Cmd.batch [ Ports.observeTablesSize (project.tables |> Dict.keys |> List.filter (\id -> not (project.layout.tables |> L.memberBy .id id))) ]
    )


hideTable : TableId -> Layout -> Layout
hideTable id layout =
    { layout
        | tables = layout.tables |> List.filter (\t -> not (t.id == id))
        , hiddenTables = ((layout.tables |> L.findBy .id id |> M.toList) ++ layout.hiddenTables) |> L.uniqueBy .id
    }


hideAllTables : Layout -> Layout
hideAllTables layout =
    { layout | tables = [], hiddenTables = (layout.tables ++ layout.hiddenTables) |> L.uniqueBy .id }


showColumn : TableId -> ColumnName -> Layout -> Layout
showColumn table column layout =
    { layout | tables = layout.tables |> L.updateBy .id table (\t -> { t | columns = t.columns |> L.addAt column (t.columns |> List.length) }) }


hideColumn : TableId -> ColumnName -> Layout -> Layout
hideColumn table column layout =
    { layout | tables = layout.tables |> L.updateBy .id table (\t -> { t | columns = t.columns |> List.filter (\c -> not (c == column)) }) }


hoverNextColumn : TableId -> ColumnName -> Model -> Model
hoverNextColumn table column model =
    let
        nextColumn : Maybe ColumnName
        nextColumn =
            model.project
                |> Maybe.andThen (\p -> p.layout.tables |> L.findBy .id table)
                |> Maybe.andThen (\t -> t.columns |> L.dropUntil (\c -> c == column) |> List.drop 1 |> List.head)
    in
    { model | hoverColumn = nextColumn |> Maybe.map (ColumnRef table) }


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
                                                    tableRelations |> Relation.withLink id column.name |> L.nonEmpty

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
                            |> L.zipWith (\name -> table.columns |> Ned.get name)
                            |> List.filter
                                (\( name, col ) ->
                                    case ( kind, col ) of
                                        ( "relations", Just _ ) ->
                                            tableRelations |> Relation.withLink id name |> L.nonEmpty

                                        ( "regular", Just _ ) ->
                                            (name |> Table.inPrimaryKey table |> M.isJust)
                                                || (tableRelations |> Relation.withLink id name |> L.nonEmpty)
                                                || (name |> Table.inUniques table |> L.nonEmpty)
                                                || (name |> Table.inIndexes table |> L.nonEmpty)

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
                    { p | isHover = enter }

                else if id /= table && p.isHover then
                    { p | isHover = False }

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
                                p.columns
                                    |> List.filter (\c -> (column.table == id && column.column == c) || (getRelations table c |> List.any (\r -> r.ref == column)))
                                    |> Set.fromList
                           )

                 else
                    Set.empty
                )
                    |> (\hoverColumns -> B.cond (p.hoverColumns == hoverColumns) p { p | hoverColumns = hoverColumns })
            )


getRelations : Maybe ErdTable -> ColumnName -> List ErdColumnRelation
getRelations table name =
    table |> Maybe.andThen (\t -> t.columns |> Ned.get name) |> M.mapOrElse (\c -> c.outRelations ++ c.inRelations) []


performShowTable : Table -> Project -> Project
performShowTable table project =
    project
        |> setLayout
            (\layout ->
                { layout
                    | tables = (getTableProps project layout table :: layout.tables) |> L.uniqueBy .id
                    , hiddenTables = layout.hiddenTables |> L.removeBy .id table.id
                }
            )


getTableProps : Project -> Layout -> Table -> TableProps
getTableProps project layout table =
    (layout.tables |> L.findBy .id table.id)
        |> M.orElse (layout.hiddenTables |> L.findBy .id table.id)
        |> Maybe.withDefault (TableProps.init project.settings project.relations table)


updateColumns : TableId -> (Table -> List ColumnName -> List ColumnName) -> Project -> Project
updateColumns id update project =
    project.tables
        |> Dict.get id
        |> M.mapOrElse (\table -> project |> setLayout (\l -> { l | tables = l.tables |> L.updateBy .id id (\t -> { t | columns = t.columns |> update table }) })) project
