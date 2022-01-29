module PagesComponents.App.Updates.Table exposing (hideAllTables, hideColumn, hideColumns, hideTable, hideTables, hoverNextColumn, showAllTables, showColumn, showColumns, showTable, showTables, sortColumns)

import Dict
import Libs.Bool exposing (cond)
import Libs.List as L
import Libs.Maybe as M
import Libs.Ned as Ned
import Libs.Nel as Nel
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.Project exposing (Project)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Layout exposing (Layout)
import Models.Project.Relation as Relation
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableProps as TableProps exposing (TableProps)
import PagesComponents.App.Models as Models exposing (Msg)
import Ports
import Services.Lenses exposing (setLayout)


showTable : TableId -> Project -> ( Project, Cmd Msg )
showTable id project =
    case project.tables |> Dict.get id of
        Just table ->
            if project.layout.tables |> L.memberBy .id id then
                ( project, Ports.toastInfo ("Table <b>" ++ TableId.show id ++ "</b> already shown") )

            else
                ( project |> performShowTable table, Cmd.batch [ Ports.observeTableSize id, Ports.activateTooltipsAndPopovers ] )

        Nothing ->
            ( project, Ports.toastError ("Can't show table <b>" ++ TableId.show id ++ "</b>: not found") )


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
                    (cond (found |> List.isEmpty) [] [ Ports.observeTablesSize found, Ports.activateTooltipsAndPopovers ]
                        ++ cond (shown |> List.isEmpty) [] [ Ports.toastInfo ("Tables " ++ (shown |> List.map TableId.show |> String.join ", ") ++ " are already shown") ]
                        ++ cond (notFound |> List.isEmpty) [] [ Ports.toastInfo ("Can't show tables " ++ (notFound |> List.map TableId.show |> String.join ", ") ++ ": can't found them") ]
                    )
                )
           )


showAllTables : Project -> ( Project, Cmd Msg )
showAllTables project =
    ( project |> setLayout (\layout -> { layout | tables = project.tables |> Dict.values |> List.map (getTableProps project layout), hiddenTables = [] })
    , Cmd.batch [ Ports.observeTablesSize (project.tables |> Dict.keys |> List.filter (\id -> not (project.layout.tables |> L.memberBy .id id))), Ports.activateTooltipsAndPopovers ]
    )


hideTable : TableId -> Layout -> Layout
hideTable id layout =
    { layout
        | tables = layout.tables |> List.filter (\t -> not (t.id == id))
        , hiddenTables = ((layout.tables |> L.findBy .id id |> M.toList) ++ layout.hiddenTables) |> L.uniqueBy .id
    }


hideTables : List TableId -> Layout -> Layout
hideTables ids layout =
    { layout
        | tables = layout.tables |> List.filter (\t -> not (List.member t.id ids))
        , hiddenTables = ((layout.tables |> List.filter (\t -> List.member t.id ids)) ++ layout.hiddenTables) |> L.uniqueBy .id
    }


hideAllTables : Layout -> Layout
hideAllTables layout =
    { layout
        | tables = []
        , hiddenTables = (layout.tables ++ layout.hiddenTables) |> L.uniqueBy .id
    }


showColumn : TableId -> ColumnName -> Layout -> Layout
showColumn table column layout =
    { layout | tables = layout.tables |> L.updateBy .id table (\t -> { t | columns = t.columns |> L.addAt column (t.columns |> List.length) }) }


hideColumn : TableId -> ColumnName -> Layout -> Layout
hideColumn table column layout =
    { layout | tables = layout.tables |> L.updateBy .id table (\t -> { t | columns = t.columns |> List.filter (\c -> not (c == column)) }) }


hoverNextColumn : TableId -> ColumnName -> Models.Model -> Models.Model
hoverNextColumn table column model =
    let
        nextColumn : Maybe ColumnName
        nextColumn =
            model.project
                |> Maybe.andThen (\p -> p.layout.tables |> L.findBy .id table)
                |> Maybe.andThen (\t -> t.columns |> L.dropUntil (\c -> c == column) |> List.drop 1 |> List.head)
    in
    { model | hover = model.hover |> (\h -> { h | column = nextColumn |> Maybe.map (ColumnRef table) }) }


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


hideColumns : TableId -> String -> Project -> Project
hideColumns id kind project =
    updateColumns id
        (\table columns ->
            project.relations
                |> List.filter (\r -> r.src.table == id)
                |> (\tableOutRelations ->
                        columns
                            |> L.zipWith (\name -> table.columns |> Ned.get name)
                            |> List.filter
                                (\( name, col ) ->
                                    case ( kind, col ) of
                                        ( "regular", Just _ ) ->
                                            (name |> Table.inPrimaryKey table |> M.isJust)
                                                || (name |> Relation.inOutRelation tableOutRelations |> L.nonEmpty)
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


showColumns : TableId -> String -> Project -> Project
showColumns id kind project =
    updateColumns id
        (\table columns ->
            columns
                ++ (table.columns
                        |> Ned.values
                        |> Nel.filter (\c -> not (columns |> List.member c.name))
                        |> List.filter
                            (\_ ->
                                case kind of
                                    "all" ->
                                        True

                                    _ ->
                                        False
                            )
                        |> List.map .name
                   )
        )
        project


updateColumns : TableId -> (Table -> List ColumnName -> List ColumnName) -> Project -> Project
updateColumns id update project =
    project.tables
        |> Dict.get id
        |> M.mapOrElse (\table -> project |> setLayout (\l -> { l | tables = l.tables |> L.updateBy .id id (\t -> { t | columns = t.columns |> update table }) })) project


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
