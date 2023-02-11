module PagesComponents.Organization_.Project_.Updates.Table exposing (goToTable, hideColumn, hideColumns, hideRelatedTables, hideTable, hoverColumn, hoverNextColumn, mapTablePropOrSelected, showAllTables, showColumn, showColumns, showRelatedTables, showTable, showTables, sortColumns, toggleNestedColumn)

import Conf
import Dict
import Libs.Bool as B
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.Delta exposing (Delta)
import Libs.Ned as Ned
import Libs.Nel as Nel
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
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps, ErdColumnPropsFlat)
import PagesComponents.Organization_.Project_.Models.ErdRelation as ErdRelation
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout as ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableProps exposing (ErdTableProps)
import PagesComponents.Organization_.Project_.Models.HideColumns as HideColumns exposing (HideColumns)
import PagesComponents.Organization_.Project_.Models.PositionHint as PositionHint exposing (PositionHint(..))
import PagesComponents.Organization_.Project_.Models.ShowColumns as ShowColumns exposing (ShowColumns)
import Ports
import Services.Lenses exposing (mapCanvas, mapColumns, mapProps, mapRelatedTables, mapTables, mapTablesL, setHighlighted, setHoverColumn, setPosition, setSelected, setShown)
import Services.Toasts as Toasts
import Set exposing (Set)
import Time


goToTable : Time.Posix -> TableId -> ErdProps -> Erd -> ( Erd, Cmd Msg )
goToTable now id viewport erd =
    (erd |> Erd.getLayoutTable id)
        |> Maybe.map (\p -> placeTableAtCenter viewport (erd |> Erd.currentLayout |> .canvas) p.props)
        |> Maybe.map (\pos -> ( erd |> Erd.mapCurrentLayoutWithTime now (mapTables (List.map (\t -> t |> mapProps (setSelected (t.id == id)))) >> mapCanvas (setPosition pos)), Cmd.none ))
        |> Maybe.withDefault ( erd, "Table " ++ TableId.show erd.settings.defaultSchema id ++ " not shown" |> Toasts.info |> Toast |> T.send )


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


showTable : Time.Posix -> TableId -> Maybe PositionHint -> Erd -> ( Erd, Cmd Msg )
showTable now id hint erd =
    case erd |> Erd.getTable id of
        Just table ->
            if erd |> Erd.isShown id then
                ( erd, "Table " ++ TableId.show erd.settings.defaultSchema id ++ " already shown" |> Toasts.info |> Toast |> T.send )

            else
                ( erd |> performShowTable now table hint, Cmd.batch [ Ports.observeTableSize table.id ] )

        Nothing ->
            ( erd, "Can't show table " ++ TableId.show erd.settings.defaultSchema id ++ ": not found" |> Toasts.error |> Toast |> T.send )


showTables : Time.Posix -> List TableId -> Maybe PositionHint -> Erd -> ( Erd, Cmd Msg )
showTables now ids hint erd =
    ids
        |> List.indexedMap (\i id -> ( id, erd |> Erd.getTable id, hint |> Maybe.map (PositionHint.move { dx = 0, dy = Conf.ui.tableHeaderHeight * toFloat i }) ))
        |> List.foldl
            (\( id, maybeTable, tableHint ) ( e, ( found, shown, notFound ) ) ->
                case maybeTable of
                    Just table ->
                        if erd |> Erd.isShown id then
                            ( e, ( found, id :: shown, notFound ) )

                        else
                            ( e |> performShowTable now table tableHint, ( id :: found, shown, notFound ) )

                    Nothing ->
                        ( e, ( found, shown, id :: notFound ) )
            )
            ( erd, ( [], [], [] ) )
        |> (\( e, ( found, shown, notFound ) ) ->
                ( e
                , Cmd.batch
                    [ Ports.observeTablesSize found
                    , B.cond (shown |> List.isEmpty) Cmd.none ("Tables " ++ (shown |> List.map (TableId.show erd.settings.defaultSchema) |> String.join ", ") ++ " are already shown" |> Toasts.info |> Toast |> T.send)
                    , B.cond (notFound |> List.isEmpty) Cmd.none ("Can't show tables " ++ (notFound |> List.map (TableId.show erd.settings.defaultSchema) |> String.join ", ") ++ ": can't found them" |> Toasts.info |> Toast |> T.send)
                    ]
                )
           )


showAllTables : Time.Posix -> Erd -> ( Erd, Cmd Msg )
showAllTables now erd =
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
    , Cmd.batch [ Ports.observeTablesSize (newTables |> List.map .id) ]
    )


hideTable : Time.Posix -> TableId -> Erd -> Erd
hideTable now id erd =
    if erd |> Erd.currentLayout |> .tables |> List.findBy .id id |> Maybe.map (.props >> .selected) |> Maybe.withDefault False then
        erd |> Erd.currentLayout |> .tables |> List.filter (.props >> .selected) |> List.foldl (\p -> performHideTable now p.id) erd

    else
        performHideTable now id erd


showRelatedTables : TableId -> Erd -> ( Erd, Cmd Msg )
showRelatedTables id erd =
    erd
        |> Erd.currentLayout
        |> .tables
        |> List.findBy .id id
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
                in
                ( erd, Cmd.batch (shows |> List.map (\( t, hint ) -> T.send (ShowTable t hint))) )
            )
            ( erd, Cmd.none )


guessHeight : TableId -> Erd -> Float
guessHeight id erd =
    (erd |> Erd.currentLayout |> .tables |> List.findBy .id id |> Maybe.map (\t -> Conf.ui.tableHeaderHeight + (Conf.ui.tableColumnHeight * (t.columns |> List.length |> toFloat))))
        |> Maybe.orElse (erd |> Erd.getTable id |> Maybe.map (\t -> Conf.ui.tableHeaderHeight + (Conf.ui.tableColumnHeight * (t.columns |> Dict.size |> toFloat |> min 15))))
        |> Maybe.withDefault 200


hideRelatedTables : TableId -> Erd -> ( Erd, Cmd Msg )
hideRelatedTables id erd =
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
    in
    ( erd, Cmd.batch (related |> List.map (\t -> T.send (HideTable t))) )


showColumn : Time.Posix -> TableId -> ColumnPath -> Erd -> Erd
showColumn now table column erd =
    erd |> Erd.mapCurrentLayoutWithTime now (mapTablesL .id table (mapColumns (ErdColumnProps.remove column >> ErdColumnProps.add column)))


hideColumn : Time.Posix -> TableId -> ColumnPath -> Erd -> Erd
hideColumn now table column erd =
    erd |> Erd.mapCurrentLayoutWithTime now (mapTablesL .id table (mapColumns (ErdColumnProps.remove column)))


hoverNextColumn : TableId -> ColumnPath -> Model -> Model
hoverNextColumn table column model =
    let
        nextColumn : Maybe ColumnPath
        nextColumn =
            model.erd
                |> Maybe.andThen (Erd.currentLayout >> .tables >> List.findBy .id table)
                |> Maybe.andThen (.columns >> ErdColumnProps.unpackAll >> List.dropUntil (\p -> p == column) >> List.drop 1 >> List.head)
    in
    model |> setHoverColumn (nextColumn |> Maybe.map (ColumnRef table))


showColumns : Time.Posix -> TableId -> ShowColumns -> Erd -> ( Erd, Cmd msg )
showColumns now id kind erd =
    ( mapColumnsForTableOrSelectedProps now
        id
        (\table columns ->
            erd.relations
                |> List.filter (Relation.linkedToTable id)
                |> (\tableRelations -> ShowColumns.filterBy kind tableRelations table columns)
                |> (\cols -> ShowColumns.sortBy kind cols)
        )
        erd
    , Cmd.none
    )


hideColumns : Time.Posix -> TableId -> HideColumns -> Erd -> ( Erd, Cmd Msg )
hideColumns now id kind erd =
    ( mapColumnsForTableOrSelectedProps now
        id
        (\table columns ->
            erd.relations
                |> List.filter (Relation.linkedToTable id)
                |> (\tableRelations ->
                        columns
                            |> ErdColumnProps.flatten
                            |> List.zipWith (\props -> table |> ErdTable.getColumnRoot props.path)
                            |> List.filter
                                (\( props, col ) ->
                                    case ( kind, col ) of
                                        ( HideColumns.Relations, Just _ ) ->
                                            props.path |> Relation.outRelation tableRelations |> List.nonEmpty

                                        ( HideColumns.Regular, Just _ ) ->
                                            (props.path |> ErdTable.inPrimaryKey table |> Maybe.isJust)
                                                || (props.path |> Relation.outRelation tableRelations |> List.nonEmpty)
                                                || (props.path |> ErdTable.inUniques table |> List.nonEmpty)
                                                || (props.path |> ErdTable.inIndexes table |> List.nonEmpty)

                                        ( HideColumns.Nullable, Just c ) ->
                                            not c.nullable

                                        ( HideColumns.All, _ ) ->
                                            False

                                        _ ->
                                            False
                                )
                            |> List.map Tuple.first
                            |> ErdColumnProps.nest
                   )
        )
        erd
    , Cmd.none
    )


toggleNestedColumn : Time.Posix -> TableId -> ColumnPath -> Bool -> Erd -> Erd
toggleNestedColumn now id path open erd =
    mapColumnsForTableOrSelectedProps now
        id
        (\table columns ->
            columns
                |> ErdColumnProps.flatten
                |> List.concatMap
                    (\column ->
                        if open && column.path == path then
                            column
                                :: (table
                                        |> ErdTable.getColumn path
                                        |> Maybe.andThen .columns
                                        |> Maybe.mapOrElse
                                            (\(ErdNestedColumns cols) ->
                                                cols
                                                    |> Ned.values
                                                    |> Nel.toList
                                                    |> List.map (.path >> ErdColumnProps.createFlat)
                                            )
                                            []
                                   )

                        else if (column.path |> ColumnPath.startsWith path) && column.path /= path then
                            []

                        else
                            [ column ]
                    )
                |> ErdColumnProps.nest
        )
        erd


sortColumns : Time.Posix -> TableId -> ColumnOrder -> Erd -> ( Erd, Cmd Msg )
sortColumns now id kind erd =
    ( mapColumnsForTableOrSelectedProps now
        id
        (\table columns ->
            columns
                |> ErdColumnProps.applyDeep
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
        )
        erd
    , Cmd.none
    )


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


performHideTable : Time.Posix -> TableId -> Erd -> Erd
performHideTable now table erd =
    erd |> Erd.mapCurrentLayoutWithTime now (mapTables (List.removeBy .id table) >> mapTables updateRelatedTables)


performShowTable : Time.Posix -> ErdTable -> Maybe PositionHint -> Erd -> Erd
performShowTable now table hint erd =
    erd
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


updateRelatedTables : List ErdTableLayout -> List ErdTableLayout
updateRelatedTables tables =
    (tables |> List.map .id |> Set.fromList)
        |> (\shownTables -> tables |> List.map (mapRelatedTables (Dict.map (\id -> setShown (shownTables |> Set.member id)))))


mapTablePropOrSelected : SchemaName -> TableId -> (ErdTableLayout -> ErdTableLayout) -> List ErdTableLayout -> ( List ErdTableLayout, Cmd Msg )
mapTablePropOrSelected defaultSchema id transform tableLayouts =
    tableLayouts
        |> List.findBy .id id
        |> Maybe.map
            (\tableLayout ->
                if tableLayout.props.selected then
                    ( tableLayouts |> List.updateBy (.props >> .selected) True transform, Cmd.none )

                else
                    ( tableLayouts |> List.updateBy .id id transform, Cmd.none )
            )
        |> Maybe.withDefault ( tableLayouts, "Table " ++ TableId.show defaultSchema id ++ " not found" |> Toasts.info |> Toast |> T.send )


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
