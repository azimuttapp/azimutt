module PagesComponents.Organization_.Project_.Updates.Table exposing (goToTable, hideColumn, hideColumns, hideRelatedTables, hideTable, hoverColumn, hoverNextColumn, mapTablePropOrSelected, mapTablePropOrSelectedTL, reshowTable, showAllTables, showColumn, showColumns, showRelatedTables, showTable, showTables, sortColumns, toggleNestedColumn)

import Conf
import Dict
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Delta exposing (Delta)
import Libs.Ned as Ned
import Libs.Nel as Nel exposing (Nel)
import Libs.Task as T
import Models.Area as Area
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.ColumnId as ColumnId exposing (ColumnId)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Relation as Relation
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models exposing (Model, Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn, ErdNestedColumns(..))
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps, ErdColumnPropsFlat, ErdColumnPropsNested(..))
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdRelation as ErdRelation
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout as ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableProps exposing (ErdTableProps)
import PagesComponents.Organization_.Project_.Models.HideColumns as HideColumns exposing (HideColumns)
import PagesComponents.Organization_.Project_.Models.PositionHint as PositionHint exposing (PositionHint(..))
import PagesComponents.Organization_.Project_.Models.ShowColumns as ShowColumns exposing (ShowColumns)
import Ports
import Services.Lenses exposing (mapCanvas, mapColumns, mapColumnsT, mapRelatedTables, mapTables, mapTablesL, mapTablesLTM, mapTablesT, setHighlighted, setHoverColumn, setPosition, setShown)
import Services.Toasts as Toasts
import Set exposing (Set)
import Time
import Track


goToTable : Time.Posix -> TableId -> ErdProps -> Erd -> ( Erd, ( Cmd Msg, List ( Msg, Msg ) ) )
goToTable now id viewport erd =
    (erd |> Erd.getLayoutTable id)
        |> Maybe.map (\t -> ( placeTableAtCenter viewport (erd |> Erd.currentLayout |> .canvas) t.props, TableId.toHtmlId id ))
        |> Maybe.map
            (\( pos, htmlId ) ->
                erd
                    |> Erd.mapCurrentLayoutTLWithTime now
                        (\l ->
                            ( l |> mapCanvas (setPosition pos) |> ErdLayout.mapSelected (\i _ -> i.id == htmlId)
                            , [ ( Batch [ CanvasPosition_ l.canvas.position, SelectItems_ (ErdLayout.getSelected l) ]
                                , Batch [ CanvasPosition_ pos, SelectItems_ [ htmlId ] ]
                                )
                              ]
                            )
                        )
                    |> Tuple.mapSecond (\h -> ( Cmd.none, h ))
            )
        |> Maybe.withDefault ( erd, ( "Table " ++ TableId.show erd.settings.defaultSchema id ++ " not shown" |> Toasts.info |> Toast |> T.send, [] ) )


placeTableAtCenter : ErdProps -> CanvasProps -> ErdTableProps -> Position.Diagram
placeTableAtCenter viewport canvas table =
    let
        tableCenter : Position.Viewport
        tableCenter =
            table |> Area.centerCanvasGrid |> Position.canvasToViewport viewport.position canvas.position canvas.zoom

        delta : Delta
        delta =
            viewport |> Area.centerViewport |> Position.diffViewport tableCenter
    in
    canvas.position |> Position.moveDiagram delta


showTable : Time.Posix -> TableId -> Maybe PositionHint -> String -> Erd -> ( Erd, ( Cmd Msg, List ( Msg, Msg ) ) )
showTable now id hint from erd =
    case erd |> Erd.getTable id of
        Just table ->
            if erd |> Erd.isShown id then
                ( erd, ( "Table " ++ TableId.show erd.settings.defaultSchema id ++ " already shown" |> Toasts.info |> Toast |> T.send, [] ) )

            else
                erd |> performShowTable now table hint |> Tuple.mapSecond (\m -> ( Cmd.batch [ Ports.observeTableSize table.id, Track.tableShown 1 from (Just erd) ], m ))

        Nothing ->
            ( erd, ( "Can't show table " ++ TableId.show erd.settings.defaultSchema id ++ ": not found" |> Toasts.error |> Toast |> T.send, [] ) )


reshowTable : Time.Posix -> Int -> ErdTableLayout -> Erd -> ( Erd, Cmd Msg )
reshowTable now index table erd =
    ( erd |> performReshowTable now index table, Cmd.batch [ Ports.observeTableSize table.id, Track.tableShown 1 "undo" (Just erd) ] )


showTables : Time.Posix -> List TableId -> Maybe PositionHint -> String -> Erd -> ( Erd, ( Cmd Msg, List ( Msg, Msg ) ) )
showTables now ids hint from erd =
    ids
        |> List.indexedMap (\i id -> ( id, erd |> Erd.getTable id, hint |> Maybe.map (PositionHint.move { dx = 0, dy = Conf.ui.table.headerHeight * toFloat i }) ))
        |> List.foldl
            (\( id, maybeTable, tableHint ) ( ( e, h ), ( found, shown, notFound ) ) ->
                case maybeTable of
                    Just table ->
                        if erd |> Erd.isShown id then
                            ( ( e, h ), ( found, id :: shown, notFound ) )

                        else
                            ( e |> performShowTable now table tableHint |> Tuple.mapSecond (\m -> m ++ h), ( id :: found, shown, notFound ) )

                    Nothing ->
                        ( ( e, h ), ( found, shown, id :: notFound ) )
            )
            ( ( erd, [] ), ( [], [], [] ) )
        |> (\( ( e, h ), ( found, shown, notFound ) ) ->
                ( e
                , ( Cmd.batch
                        [ Ports.observeTablesSize found
                        , B.cond (shown |> List.isEmpty) Cmd.none (Track.tableShown (List.length shown) from (Just erd))
                        , B.cond (shown |> List.isEmpty) Cmd.none ("Tables " ++ (shown |> List.map (TableId.show erd.settings.defaultSchema) |> String.join ", ") ++ " are already shown" |> Toasts.info |> Toast |> T.send)
                        , B.cond (notFound |> List.isEmpty) Cmd.none ("Can't show tables " ++ (notFound |> List.map (TableId.show erd.settings.defaultSchema) |> String.join ", ") ++ ": can't found them" |> Toasts.info |> Toast |> T.send)
                        ]
                  , h |> List.reverse
                  )
                )
           )


showAllTables : Time.Posix -> String -> Erd -> ( Erd, ( Cmd Msg, List ( Msg, Msg ) ) )
showAllTables now from erd =
    let
        shownIds : Set TableId
        shownIds =
            erd |> Erd.currentLayout |> .tables |> List.map .id |> Set.fromList

        tablesToShow : List ErdTable
        tablesToShow =
            erd.tables |> Dict.values |> List.filter (\t -> shownIds |> Set.member t.id |> not)

        newTables : List ErdTableLayout
        newTables =
            tablesToShow |> List.map (\t -> t |> ErdTableLayout.init erd.settings shownIds (erd.relationsByTable |> Dict.getOrElse t.id []) erd.settings.collapseTableColumns Nothing)
    in
    ( erd |> Erd.mapCurrentLayoutWithTime now (mapTables (\old -> newTables ++ old))
    , ( Cmd.batch
            [ Ports.observeTablesSize (newTables |> List.map .id)
            , B.cond (newTables |> List.isEmpty) Cmd.none (Track.tableShown (List.length newTables) from (Just erd))
            ]
      , [ ( tablesToShow |> List.map (\t -> HideTable t.id) |> Batch, ShowAllTables "redo" ) ]
      )
    )


hideTable : Time.Posix -> TableId -> Erd -> ( Erd, List ( Msg, Msg ) )
hideTable now id erd =
    -- FIXME: must keep table details in history to get back color, shown columns and so on
    if erd |> Erd.currentLayout |> .tables |> List.findBy .id id |> Maybe.map (.props >> .selected) |> Maybe.withDefault False then
        (erd |> Erd.currentLayout |> .tables)
            |> List.filter (.props >> .selected)
            |> List.foldl (\p ( e, h ) -> performHideTable now p.id e |> Tuple.mapSecond (\m -> m ++ h)) ( erd, [] )

    else
        performHideTable now id erd


showRelatedTables : Time.Posix -> TableId -> Erd -> ( Erd, ( Cmd Msg, List ( Msg, Msg ) ) )
showRelatedTables now id erd =
    (erd |> Erd.currentLayout |> .tables |> List.findBy .id id)
        |> Maybe.mapOrElse
            (\table ->
                let
                    padding : Delta
                    padding =
                        { dx = 50, dy = 20 }

                    related : List TableId
                    related =
                        erd.relationsByTable
                            |> Dict.getOrElse id []
                            |> List.map
                                (\r ->
                                    if r.src.table == id then
                                        r.ref.table

                                    else
                                        r.src.table
                                )
                            |> List.unique

                    toShow : List ( TableId, Float )
                    toShow =
                        related |> List.filterNot (\t -> erd |> Erd.currentLayout |> .tables |> List.memberBy .id t) |> List.map (\t -> ( t, guessHeight t erd ))

                    ( tablePos, tableSize ) =
                        ( table.props.position |> Position.extractGrid, table.props.size |> Size.extractCanvas )

                    left : Float
                    left =
                        tablePos.left + tableSize.width + padding.dx

                    height : Float
                    height =
                        toShow |> List.map (\( _, h ) -> h) |> List.intersperse padding.dy |> List.foldl (\h acc -> h + acc) 0

                    top : Float
                    top =
                        tablePos.top + (tableSize.height / 2) - (height / 2)

                    shows : List ( TableId, Maybe PositionHint )
                    shows =
                        toShow |> List.foldl (\( t, h ) ( cur, res ) -> ( cur + h + padding.dy, ( t, Just (PlaceAt (Position.grid { left = left, top = cur })) ) :: res )) ( top, [] ) |> Tuple.second

                    ( newErd, cmds ) =
                        shows |> List.foldl (\( t, h ) ( e, cs ) -> showTable now t h "related" e |> Tuple.mapSecond (\( c, _ ) -> c :: cs)) ( erd, [] )

                    ( back, forward ) =
                        ( shows |> List.map (\( t, _ ) -> HideTable t) |> Batch
                        , shows |> List.map (\( t, h ) -> ShowTable t h "related") |> Batch
                        )
                in
                ( newErd, ( Cmd.batch cmds, [ ( back, forward ) ] ) )
            )
            ( erd, ( Cmd.none, [] ) )


guessHeight : TableId -> Erd -> Float
guessHeight id erd =
    (erd |> Erd.currentLayout |> .tables |> List.findBy .id id |> Maybe.map (\t -> Conf.ui.table.headerHeight + (Conf.ui.table.columnHeight * (t.columns |> List.length |> toFloat))))
        |> Maybe.orElse (erd |> Erd.getTable id |> Maybe.map (\t -> Conf.ui.table.headerHeight + (Conf.ui.table.columnHeight * (t.columns |> Dict.size |> toFloat |> min 15))))
        |> Maybe.withDefault 200


hideRelatedTables : Time.Posix -> TableId -> Erd -> ( Erd, ( Cmd Msg, List ( Msg, Msg ) ) )
hideRelatedTables now id erd =
    let
        related : List TableId
        related =
            erd.relationsByTable
                |> Dict.getOrElse id []
                |> List.map
                    (\r ->
                        if r.src.table == id then
                            r.ref.table

                        else
                            r.src.table
                    )

        shownTables : List ( ErdTableLayout, Int )
        shownTables =
            erd |> Erd.currentLayout |> .tables |> List.zipWithIndex |> List.filter (\( t, _ ) -> related |> List.member t.id)
    in
    ( related |> List.foldl (\t e -> hideTable now t e |> Tuple.first) erd
    , ( Cmd.none, [ ( shownTables |> List.map (\( t, i ) -> ReshowTable_ i t) |> Batch, related |> List.map HideTable |> Batch ) ] )
    )


showColumn : Time.Posix -> Int -> ColumnRef -> Erd -> ( Erd, List ( Msg, Msg ) )
showColumn now index column erd =
    ( erd |> Erd.mapCurrentLayoutWithTime now (mapTablesL .id column.table (mapColumns (ErdColumnProps.remove column.column >> ErdColumnProps.insertAt index column.column)))
    , [ ( HideColumn column, ShowColumn index column ) ]
    )


hideColumn : Time.Posix -> ColumnRef -> Erd -> ( Erd, List ( Msg, Msg ) )
hideColumn now column erd =
    erd
        |> Erd.mapCurrentLayoutTLWithTime now
            (mapTablesLTM .id column.table (mapColumnsT (ErdColumnProps.removeWithIndex column.column))
                >> Tuple.mapSecond (Maybe.map (\i -> ( ShowColumn i column, HideColumn column )) >> Maybe.toList)
            )


hoverNextColumn : ColumnRef -> Model -> Model
hoverNextColumn column model =
    let
        nextColumn : Maybe ColumnPath
        nextColumn =
            model.erd
                |> Maybe.andThen (Erd.currentLayout >> .tables >> List.findBy .id column.table)
                |> Maybe.andThen (.columns >> ErdColumnProps.unpackAll >> List.dropUntil (\p -> p == column.column) >> List.drop 1 >> List.head)
    in
    model |> setHoverColumn (nextColumn |> Maybe.map (ColumnRef column.table))


showColumns : Time.Posix -> TableId -> ShowColumns -> Erd -> ( Erd, ( Cmd Msg, List ( Msg, Msg ) ) )
showColumns now id kind erd =
    mapColumnsForTableOrSelectedPropsTL now
        id
        (\table columns ->
            erd.relations
                |> List.filter (Relation.linkedToTable id)
                |> (\tableRelations -> ShowColumns.filterBy kind tableRelations table columns)
                |> (\cols -> ShowColumns.sortBy kind cols)
                |> (\cols -> ( cols, [ ( SetColumns_ table.id columns, SetColumns_ table.id cols ) ] ))
        )
        erd
        |> Tuple.mapSecond (\h -> ( Cmd.none, h ))


hideColumns : Time.Posix -> TableId -> HideColumns -> Erd -> ( Erd, ( Cmd Msg, List ( Msg, Msg ) ) )
hideColumns now id kind erd =
    mapColumnsForTableOrSelectedPropsTL now
        id
        (\table columns ->
            erd.relations
                |> List.filter (Relation.linkedToTable id)
                |> (\tableRelations ->
                        columns
                            |> ErdColumnProps.filter
                                (\path _ ->
                                    case ( kind, table |> ErdTable.getColumn path ) of
                                        ( HideColumns.Relations, Just _ ) ->
                                            path |> Relation.outRelation tableRelations |> List.nonEmpty

                                        ( HideColumns.Regular, Just _ ) ->
                                            (path |> ErdTable.inPrimaryKey table |> Maybe.isJust)
                                                || (path |> Relation.outRelation tableRelations |> List.nonEmpty)
                                                || (path |> ErdTable.inUniques table |> List.nonEmpty)
                                                || (path |> ErdTable.inIndexes table |> List.nonEmpty)

                                        ( HideColumns.Nullable, Just c ) ->
                                            not c.nullable

                                        ( HideColumns.All, _ ) ->
                                            False

                                        _ ->
                                            False
                                )
                            |> (\cols -> ( cols, [ ( SetColumns_ table.id columns, SetColumns_ table.id cols ) ] ))
                   )
        )
        erd
        |> Tuple.mapSecond (\h -> ( Cmd.none, h ))


sortColumns : Time.Posix -> TableId -> ColumnOrder -> Erd -> ( Erd, ( Cmd Msg, List ( Msg, Msg ) ) )
sortColumns now id kind erd =
    mapColumnsForTableOrSelectedPropsTL now
        id
        (\table columns ->
            columns
                |> ErdColumnProps.mapAll
                    (\path cols ->
                        cols
                            |> List.filterMap
                                (\col ->
                                    table
                                        |> ErdTable.getColumn (path |> Maybe.mapOrElse (ColumnPath.child col.name) (ColumnPath.fromString col.name))
                                        |> Maybe.map (\c -> ( c, col ))
                                )
                            |> ColumnOrder.sortBy kind table erd.relations
                            |> List.map Tuple.second
                    )
                |> (\cols -> ( cols, [ ( SetColumns_ table.id columns, SetColumns_ table.id cols ) ] ))
        )
        erd
        |> Tuple.mapSecond (\h -> ( Cmd.none, h ))


toggleNestedColumn : Time.Posix -> TableId -> ColumnPath -> Bool -> Erd -> Erd
toggleNestedColumn now id path open erd =
    mapColumnsForTableOrSelectedProps now
        id
        (\table columns ->
            columns
                |> ErdColumnProps.map
                    (\p col ->
                        if p == path then
                            if open then
                                col
                                    |> ErdColumnProps.createChildren
                                        (table
                                            |> ErdTable.getColumn path
                                            |> Maybe.andThen .columns
                                            |> Maybe.mapOrElse (\(ErdNestedColumns cols) -> cols |> Ned.values |> Nel.toList |> List.map (.path >> Nel.last)) []
                                        )

                            else
                                col |> ErdColumnProps.createChildren []

                        else
                            col
                    )
        )
        erd


hoverColumn : ColumnRef -> Bool -> Erd -> List ErdTableLayout -> List ErdTableLayout
hoverColumn column enter erd tables =
    let
        highlightedColumns : Set ColumnId
        highlightedColumns =
            if enter then
                erd.relationsByTable
                    |> Dict.getOrElse column.table []
                    |> List.filter (ErdRelation.linkedTo column)
                    |> List.concatMap (\r -> [ ColumnId.fromRef r.src, ColumnId.fromRef r.ref ])
                    |> Set.fromList
                    |> Set.insert (ColumnId.fromRef column)

            else
                Set.empty
    in
    tables |> List.map (\t -> t |> mapColumns (ErdColumnProps.map (\p c -> c |> setHighlighted (highlightedColumns |> Set.member (ColumnId.from t { path = p })))))


performHideTable : Time.Posix -> TableId -> Erd -> ( Erd, List ( Msg, Msg ) )
performHideTable now id erd =
    (erd |> Erd.currentLayout |> .tables |> List.zipWithIndex |> List.find (\( t, _ ) -> t.id == id))
        |> Maybe.map
            (\( table, index ) ->
                ( erd |> Erd.mapCurrentLayoutWithTime now (mapTables (List.removeBy .id id) >> mapTables updateRelatedTables)
                , [ ( ReshowTable_ index table, HideTable id ) ]
                )
            )
        |> Maybe.withDefault ( erd, [] )


performShowTable : Time.Posix -> ErdTable -> Maybe PositionHint -> Erd -> ( Erd, List ( Msg, Msg ) )
performShowTable now table hint erd =
    ( erd
        |> Erd.mapCurrentLayoutWithTime now
            (mapTables
                (\tables ->
                    -- initial position is computed in frontend/src/PagesComponents/Organization_/Project_/Updates.elm:502#computeInitialPosition when size is known
                    ErdTableLayout.init erd.settings
                        (tables |> List.map .id |> Set.fromList)
                        (erd.relationsByTable |> Dict.getOrElse table.id [])
                        erd.settings.collapseTableColumns
                        hint
                        table
                        :: tables
                )
                >> mapTables updateRelatedTables
            )
    , [ ( HideTable table.id, ShowTable table.id hint "undo" ) ]
    )


performReshowTable : Time.Posix -> Int -> ErdTableLayout -> Erd -> Erd
performReshowTable now index table erd =
    erd |> Erd.mapCurrentLayoutWithTime now (mapTables (List.insertAt index table) >> mapTables updateRelatedTables)


updateRelatedTables : List ErdTableLayout -> List ErdTableLayout
updateRelatedTables tables =
    (tables |> List.map .id |> Set.fromList)
        |> (\shownTables -> tables |> List.map (mapRelatedTables (Dict.map (\id -> setShown (shownTables |> Set.member id)))))


mapTablePropOrSelected : SchemaName -> TableId -> (ErdTableLayout -> ErdTableLayout) -> List ErdTableLayout -> ( List ErdTableLayout, Cmd Msg )
mapTablePropOrSelected defaultSchema id transform tableLayouts =
    (tableLayouts |> List.findBy .id id)
        |> Maybe.map
            (\tableLayout ->
                if tableLayout.props.selected then
                    ( tableLayouts |> List.mapBy (.props >> .selected) True transform, Cmd.none )

                else
                    ( tableLayouts |> List.mapBy .id id transform, Cmd.none )
            )
        |> Maybe.withDefault ( tableLayouts, "Table " ++ TableId.show defaultSchema id ++ " not found" |> Toasts.info |> Toast |> T.send )


mapTablePropOrSelectedTL : SchemaName -> Bool -> TableId -> (ErdTableLayout -> ( ErdTableLayout, List a )) -> List ErdTableLayout -> ( List ErdTableLayout, ( Cmd Msg, List a ) )
mapTablePropOrSelectedTL defaultSchema extendToSelected id transform tableLayouts =
    (tableLayouts |> List.findBy .id id)
        |> Maybe.map
            (\tableLayout ->
                if tableLayout.props.selected && extendToSelected then
                    tableLayouts |> List.mapByTL (.props >> .selected) True transform |> Tuple.mapSecond (\l -> ( Cmd.none, l ))

                else
                    tableLayouts |> List.mapByTL .id id transform |> Tuple.mapSecond (\l -> ( Cmd.none, l ))
            )
        |> Maybe.withDefault ( tableLayouts, ( "Table " ++ TableId.show defaultSchema id ++ " not found" |> Toasts.info |> Toast |> T.send, [] ) )


mapColumnsForTableOrSelectedProps : Time.Posix -> TableId -> (ErdTable -> List ErdColumnProps -> List ErdColumnProps) -> Erd -> Erd
mapColumnsForTableOrSelectedProps now id transform erd =
    let
        selected : Bool
        selected =
            erd |> Erd.currentLayout |> .tables |> List.findBy .id id |> Maybe.mapOrElse (.props >> .selected) False
    in
    erd
        |> Erd.mapCurrentLayoutWithTime now
            (mapTables
                (List.map
                    (\props ->
                        if props.id == id || (selected && props.props.selected) then
                            erd.tables
                                |> Dict.get props.id
                                |> Maybe.map (\table -> props |> mapColumns (transform table >> ErdColumnProps.filter (\p _ -> table |> ErdTable.getColumn p |> Maybe.isJust)))
                                |> Maybe.withDefault props

                        else
                            props
                    )
                )
            )


mapColumnsForTableOrSelectedPropsTL : Time.Posix -> TableId -> (ErdTable -> List ErdColumnProps -> ( List ErdColumnProps, List a )) -> Erd -> ( Erd, List a )
mapColumnsForTableOrSelectedPropsTL now id transform erd =
    let
        selected : Bool
        selected =
            erd |> Erd.currentLayout |> .tables |> List.findBy .id id |> Maybe.mapOrElse (.props >> .selected) False
    in
    erd
        |> Erd.mapCurrentLayoutTLWithTime now
            (mapTablesT
                (List.mapTL
                    (\props ->
                        if props.id == id || (selected && props.props.selected) then
                            (erd.tables |> Dict.get props.id)
                                |> Maybe.map (\table -> props |> mapColumnsT (transform table >> Tuple.mapFirst (ErdColumnProps.filter (\p _ -> table |> ErdTable.getColumn p |> Maybe.isJust))))
                                |> Maybe.withDefault ( props, [] )

                        else
                            ( props, [] )
                    )
                )
            )
