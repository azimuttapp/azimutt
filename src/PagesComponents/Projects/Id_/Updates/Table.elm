module PagesComponents.Projects.Id_.Updates.Table exposing (hideColumns, hideTable, showColumns, showTable, sortColumns)

import Dict
import Libs.List as L
import Libs.Maybe as M
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.Task as T
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.Project exposing (Project)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Layout exposing (Layout)
import Models.Project.Relation as Relation
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableProps as TableProps exposing (TableProps)
import PagesComponents.App.Updates.Helpers exposing (setLayout)
import PagesComponents.Projects.Id_.Models exposing (Msg, toastError, toastInfo)
import Ports exposing (observeTableSize)


showTable : TableId -> Project -> ( Project, Cmd Msg )
showTable id project =
    case project.tables |> Dict.get id of
        Just table ->
            if project.layout.tables |> L.memberBy .id id then
                ( project, T.send (toastInfo ("Table <b>" ++ TableId.show id ++ "</b> already shown")) )

            else
                ( project |> performShowTable table, Cmd.batch [ observeTableSize id ] )

        Nothing ->
            ( project, T.send (toastError ("Can't show table <b>" ++ TableId.show id ++ "</b>: not found")) )


hideTable : TableId -> Layout -> Layout
hideTable id layout =
    { layout
        | tables = layout.tables |> List.filter (\t -> not (t.id == id))
        , hiddenTables = ((layout.tables |> L.findBy .id id |> M.toList) ++ layout.hiddenTables) |> L.uniqueBy .id
    }


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
