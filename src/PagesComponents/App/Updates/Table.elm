module PagesComponents.App.Updates.Table exposing (hideAllTables, hideColumn, hideColumns, hideTable, hideTables, hoverNextColumn, showAllTables, showColumn, showColumns, showTable, showTables, sortColumns)

import Dict
import Libs.Bool exposing (cond)
import Libs.List as L
import Libs.Maybe as M
import Libs.Ned as Ned
import Libs.Nel as Nel
import Models.Project exposing (ColumnName, ColumnRef, Layout, Schema, Table, TableId, inIndexes, inOutRelation, inPrimaryKey, inUniques, initTableProps, showTableId, withNullableInfo)
import PagesComponents.App.Models as Models exposing (Msg)
import PagesComponents.App.Updates.Helpers exposing (setLayout)
import Ports exposing (activateTooltipsAndPopovers, observeTableSize, observeTablesSize, toastError, toastInfo)


showTable : TableId -> Schema -> ( Schema, Cmd Msg )
showTable id schema =
    case schema.tables |> Dict.get id of
        Just table ->
            if schema.layout.tables |> L.memberBy .id id then
                ( schema, toastInfo ("Table <b>" ++ showTableId id ++ "</b> already shown") )

            else
                ( schema |> performShowTable id table, Cmd.batch [ observeTableSize id, activateTooltipsAndPopovers ] )

        Nothing ->
            ( schema, toastError ("Can't show table <b>" ++ showTableId id ++ "</b>: not found") )


showTables : List TableId -> Schema -> ( Schema, Cmd Msg )
showTables ids schema =
    ids
        |> L.zipWith (\id -> schema.tables |> Dict.get id)
        |> List.foldr
            (\( id, maybeTable ) ( s, ( found, shown, notFound ) ) ->
                case maybeTable of
                    Just table ->
                        if schema.layout.tables |> L.memberBy .id id then
                            ( s, ( found, id :: shown, notFound ) )

                        else
                            ( s |> performShowTable id table, ( id :: found, shown, notFound ) )

                    Nothing ->
                        ( s, ( found, shown, id :: notFound ) )
            )
            ( schema, ( [], [], [] ) )
        |> (\( s, ( found, shown, notFound ) ) ->
                ( s
                , Cmd.batch
                    (cond (found |> List.isEmpty) [] [ observeTablesSize found, activateTooltipsAndPopovers ]
                        ++ cond (shown |> List.isEmpty) [] [ toastInfo ("Tables " ++ (shown |> List.map showTableId |> String.join ", ") ++ " are ealready shown") ]
                        ++ cond (notFound |> List.isEmpty) [] [ toastInfo ("Can't show tables " ++ (notFound |> List.map showTableId |> String.join ", ") ++ ": can't found them") ]
                    )
                )
           )


showAllTables : Schema -> ( Schema, Cmd Msg )
showAllTables schema =
    ( schema
        |> setLayout
            (\l ->
                { l
                    | tables = schema.tables |> Dict.toList |> List.map (\( id, t ) -> l.tables |> L.findBy .id id |> M.orElse (l.hiddenTables |> L.findBy .id id) |> Maybe.withDefault (initTableProps t))
                    , hiddenTables = []
                }
            )
    , Cmd.batch [ observeTablesSize (schema.tables |> Dict.keys |> List.filter (\id -> not (schema.layout.tables |> L.memberBy .id id))), activateTooltipsAndPopovers ]
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
                |> Maybe.andThen (\p -> p.schema.layout.tables |> L.findBy .id table)
                |> Maybe.andThen (\t -> t.columns |> L.dropUntil (\c -> c == column) |> List.drop 1 |> List.head)
    in
    { model | hover = model.hover |> (\h -> { h | column = nextColumn |> Maybe.map (ColumnRef table) }) }


sortColumns : TableId -> String -> Schema -> Schema
sortColumns id kind schema =
    updateColumns id
        (\table columns ->
            schema.relations
                |> List.filter (\r -> r.src.table == id)
                |> (\tableOutRelations ->
                        columns
                            |> L.zipWith (\name -> table.columns |> Ned.get name)
                            |> (case kind of
                                    "property" ->
                                        List.sortBy
                                            (\( name, col ) ->
                                                col
                                                    |> Maybe.map
                                                        (\c ->
                                                            if name |> inPrimaryKey table |> M.isJust then
                                                                ( 0 + sortOffset c.nullable, name |> String.toLower )

                                                            else if name |> inOutRelation tableOutRelations |> L.nonEmpty then
                                                                ( 1 + sortOffset c.nullable, name |> String.toLower )

                                                            else if name |> inUniques table |> L.nonEmpty then
                                                                ( 2 + sortOffset c.nullable, name |> String.toLower )

                                                            else if name |> inIndexes table |> L.nonEmpty then
                                                                ( 3 + sortOffset c.nullable, name |> String.toLower )

                                                            else
                                                                ( 4 + sortOffset c.nullable, name |> String.toLower )
                                                        )
                                                    |> Maybe.withDefault ( 5, name |> String.toLower )
                                            )

                                    "name" ->
                                        List.sortBy (\( name, _ ) -> name |> String.toLower)

                                    "sql" ->
                                        List.sortBy (\( _, col ) -> col |> Maybe.map .index |> Maybe.withDefault (table.columns |> Ned.size))

                                    "type" ->
                                        List.sortBy (\( _, col ) -> col |> Maybe.map (\c -> c.kind |> String.toLower |> withNullableInfo c.nullable) |> Maybe.withDefault "~")

                                    _ ->
                                        List.sortBy (\( _, col ) -> col |> Maybe.map .index |> Maybe.withDefault (table.columns |> Ned.size))
                               )
                            |> List.map Tuple.first
                   )
        )
        schema


sortOffset : Bool -> Float
sortOffset b =
    if b then
        0.5

    else
        0


hideColumns : TableId -> String -> Schema -> Schema
hideColumns id kind schema =
    updateColumns id
        (\table columns ->
            schema.relations
                |> List.filter (\r -> r.src.table == id)
                |> (\tableOutRelations ->
                        columns
                            |> L.zipWith (\name -> table.columns |> Ned.get name)
                            |> List.filter
                                (\( name, col ) ->
                                    case ( kind, col ) of
                                        ( "regular", Just _ ) ->
                                            (name |> inPrimaryKey table |> M.isJust)
                                                || (name |> inOutRelation tableOutRelations |> L.nonEmpty)
                                                || (name |> inUniques table |> L.nonEmpty)
                                                || (name |> inIndexes table |> L.nonEmpty)

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
        schema


showColumns : TableId -> String -> Schema -> Schema
showColumns id kind schema =
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
        schema


updateColumns : TableId -> (Table -> List ColumnName -> List ColumnName) -> Schema -> Schema
updateColumns id update schema =
    schema.tables
        |> Dict.get id
        |> Maybe.map (\table -> schema |> setLayout (\l -> { l | tables = l.tables |> L.updateBy .id id (\t -> { t | columns = t.columns |> update table }) }))
        |> Maybe.withDefault schema


performShowTable : TableId -> Table -> Schema -> Schema
performShowTable id table schema =
    schema |> setLayout (\l -> { l | tables = ((l.hiddenTables |> L.findBy .id id |> Maybe.withDefault (initTableProps table)) :: l.tables) |> L.uniqueBy .id })
