module Components.Organisms.TableRow exposing (DocState, Model, Msg(..), SharedDocState, TableRowHover, TableRowRelation, TableRowRelationColumn, TableRowSuccess, canBroadcast, doc, docInit, init, initRelation, initRelationColumn, update, view)

import Array
import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon
import Components.Atoms.Icons as Icons
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Popover as Popover
import DataSources.DbMiner.DbQuery as DbQuery
import DataSources.DbMiner.DbTypes exposing (DbColumnRef, FilterOperation(..), FilterOperator(..), IncomingRowsQuery, RowQuery, TableFilter)
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, dd, div, dl, dt, p, span, text)
import Html.Attributes exposing (class, classList, id, title, type_)
import Html.Events exposing (onClick, onMouseEnter, onMouseLeave)
import Html.Events.Extra.Mouse exposing (Button(..))
import Html.Keyed as Keyed
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css)
import Libs.Html.Events exposing (PointerEvent, onContextMenu, onDblClick, onPointerUp)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind(..))
import Libs.Models.DateTime as DateTime
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Notes exposing (Notes)
import Libs.Models.Platform as Platform exposing (Platform)
import Libs.Nel as Nel exposing (Nel)
import Libs.Result as Result
import Libs.String as String
import Libs.Tailwind as Tw exposing (Color, TwClass, focus)
import Libs.Task as T
import Libs.Time as Time
import Models.DbSource as DbSource exposing (DbSource)
import Models.DbSourceInfo exposing (DbSourceInfo)
import Models.DbSourceInfoWithUrl as DbSourceInfoWithUrl exposing (DbSourceInfoWithUrl)
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Position as Position
import Models.Project as Project
import Models.Project.Column as Column exposing (Column)
import Models.Project.ColumnMeta exposing (ColumnMeta)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.DatabaseUrlStorage as DatabaseUrlStorage
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.RowPrimaryKey as RowPrimaryKey exposing (RowPrimaryKey)
import Models.Project.RowValue exposing (RowValue)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableMeta exposing (TableMeta)
import Models.Project.TableName exposing (TableName)
import Models.Project.TableRow as TableRow exposing (State(..), TableRow, TableRowColumn)
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.QueryResult exposing (QueryResult, QueryResultSuccess)
import Models.Size as Size
import Models.SqlQuery exposing (SqlQuery, SqlQueryOrigin)
import Models.UserRole as UserRole
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdColumnRef
import PagesComponents.Organization_.Project_.Models.ErdConf as ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdOrigin as ErdOrigin
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.PositionHint as PositionHint exposing (PositionHint)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import PagesComponents.Organization_.Project_.Views.Modals.ColumnRowContextMenu as ColumnRowContextMenu
import PagesComponents.Organization_.Project_.Views.Modals.TableRowContextMenu as TableRowContextMenu
import Ports
import Services.Lenses exposing (mapCollapsedT, mapColumns, mapHidden, mapSelected, mapShowHiddenColumns, mapState, mapStateT, setPrevious, setState)
import Services.Toasts as Toasts
import Set exposing (Set)
import Time
import Track



-- TODO: allow to change source for a table row? (click on the footer)


type alias Model =
    TableRow


type Msg
    = GotResult QueryResult
    | Refresh
    | Cancel
    | SetState State
    | SetCollapsed Bool
    | ShowColumn ColumnPathStr
    | HideColumn ColumnPathStr
    | ToggleHiddenColumns
    | ToggleIncomingRows HtmlId TableRowColumn (Dict TableId IncomingRowsQuery)
    | GotIncomingRows ColumnPath QueryResult


type alias TableRowSuccess =
    { row : TableRow, state : TableRow.SuccessState, color : Color }


type alias TableRowRelation =
    { id : String, src : TableRowRelationColumn, ref : TableRowRelationColumn }


type alias TableRowRelationColumn =
    { row : TableRow, state : TableRow.SuccessState, color : Color, column : TableRowColumn, index : Int }


type alias TableRowHover =
    ( TableRow.Id, Maybe ColumnPath )



-- INIT


dbPrefix : String
dbPrefix =
    "table-row"


init : ProjectInfo -> TableRow.Id -> Time.Posix -> DbSourceInfoWithUrl -> RowQuery -> Set ColumnPathStr -> Maybe TableRow.SuccessState -> Maybe PositionHint -> ( Model, Cmd msg )
init project id now source query hidden previous hint =
    let
        sqlQuery : SqlQueryOrigin
        sqlQuery =
            DbQuery.findRow source.db.kind query
    in
    ( { id = id
      , positionHint = hint
      , position = Position.zeroGrid
      , size = Size.zeroCanvas
      , source = source.id
      , table = query.table
      , primaryKey = query.primaryKey
      , state = previous |> Maybe.mapOrElse StateSuccess (StateLoading { query = sqlQuery, startedAt = now, previous = Nothing })
      , hidden =
            if Set.isEmpty hidden then
                previous |> Maybe.mapOrElse defaultHidden Set.empty

            else
                hidden
      , showHiddenColumns = False
      , selected = False
      , collapsed = False
      }
    , Cmd.batch
        [ previous |> Maybe.mapOrElse (\_ -> Cmd.none) (Ports.runDatabaseQuery (dbPrefix ++ "/" ++ String.fromInt id) source.db.url sqlQuery)
        , Track.tableRowOpened previous source sqlQuery project
        ]
    )


initFailure : SqlQueryOrigin -> Maybe TableRow.SuccessState -> Time.Posix -> Time.Posix -> String -> TableRow.State
initFailure query previous started finished err =
    StateFailure { query = query, error = err, startedAt = started, failedAt = finished, previous = previous }


initSuccess : Time.Posix -> Time.Posix -> QueryResultSuccess -> State
initSuccess started finished res =
    StateSuccess
        { columns = res.columns |> List.filterMap (\c -> res.rows |> List.head |> Maybe.andThen (Dict.get c.pathStr) |> Maybe.map (\v -> { path = c.path, pathStr = c.pathStr, value = v, linkedBy = Dict.empty }))
        , startedAt = started
        , loadedAt = finished
        }


initRelationColumn : TableRowSuccess -> ( TableRowColumn, Int ) -> TableRowRelationColumn
initRelationColumn row ( column, index ) =
    { row = row.row, state = row.state, color = row.color, column = column, index = index }


initRelation : TableRowRelationColumn -> TableRowRelationColumn -> TableRowRelation
initRelation src ref =
    let
        rowId : TableRow -> String
        rowId row =
            TableId.toString row.table :: (row.primaryKey |> Nel.toList |> List.map (.value >> DbValue.toString)) |> String.join "-"
    in
    { id = [ SourceId.toString src.row.source, rowId src.row, String.fromInt src.index, rowId ref.row, String.fromInt ref.index ] |> String.join "-", src = src, ref = ref }



-- UPDATE


update : (Msg -> msg) -> (HtmlId -> msg) -> (Toasts.Msg -> msg) -> msg -> (TableRow -> msg) -> Time.Posix -> ProjectInfo -> List Source -> HtmlId -> Msg -> Model -> ( Model, Extra msg )
update wrap toggleDropdown showToast deleteTableRow unDeleteTableRow now project sources openedDropdown msg model =
    case msg of
        GotResult res ->
            model
                |> mapStateLoadingTM (\l -> ( res.result |> Result.fold (initFailure l.query l.previous res.started res.finished) (initSuccess res.started res.finished), l.previous ))
                |> (\( newModel, previous ) ->
                        ( newModel
                            |> mapHidden
                                (\h ->
                                    if Set.isEmpty h then
                                        res.result |> Result.mapOrElse defaultHidden Set.empty

                                    else
                                        h
                                )
                        , Extra.new
                            (Track.tableRowResult res project)
                            (previous
                                |> Maybe.map (\s -> ( wrap (SetState (StateSuccess s)), wrap (SetState newModel.state) ))
                                |> Maybe.withDefault ( deleteTableRow, unDeleteTableRow newModel )
                             -- if no previous, add history for show table row (initial loading, cf frontend/src/PagesComponents/Organization_/Project_/Updates/TableRow.elm#showTableRow)
                            )
                        )
                   )

        Refresh ->
            withDbSource "refresh row"
                showToast
                sources
                model
                (\dbSrc ->
                    let
                        sqlQuery : SqlQueryOrigin
                        sqlQuery =
                            DbQuery.findRow dbSrc.db.kind { source = dbSrc.id, table = model.table, primaryKey = model.primaryKey }
                    in
                    ( model |> setState (StateLoading { query = sqlQuery, startedAt = now, previous = model |> TableRow.stateSuccess })
                    , Ports.runDatabaseQuery (dbPrefix ++ "/" ++ String.fromInt model.id) dbSrc.db.url sqlQuery |> Extra.cmd
                    )
                )

        Cancel ->
            ( model |> mapStateLoading (\l -> initFailure l.query l.previous l.startedAt now "Query canceled"), Extra.none )

        SetState state ->
            model |> mapStateT (\s -> ( state, Extra.history ( wrap (SetState s), wrap msg ) ))

        SetCollapsed value ->
            model |> mapCollapsedT (\c -> ( value, Extra.history ( wrap (SetCollapsed c), wrap msg ) ))

        ShowColumn pathStr ->
            ( model |> mapHidden (Set.remove pathStr), Extra.history ( wrap (HideColumn pathStr), wrap msg ) )

        HideColumn pathStr ->
            ( model |> mapHidden (Set.insert pathStr), Extra.history ( wrap (ShowColumn pathStr), wrap msg ) )

        ToggleHiddenColumns ->
            ( model |> mapShowHiddenColumns not, Extra.history ( wrap ToggleHiddenColumns, wrap ToggleHiddenColumns ) )

        ToggleIncomingRows dropdown column relations ->
            if Dict.isEmpty column.linkedBy && openedDropdown /= dropdown then
                withDbSource "get incoming rows"
                    showToast
                    sources
                    model
                    (\dbSrc ->
                        let
                            sqlQuery : SqlQueryOrigin
                            sqlQuery =
                                DbQuery.incomingRows dbSrc.db.kind relations { source = dbSrc.id, table = model.table, primaryKey = model.primaryKey }
                        in
                        ( model, Extra.cmdL [ toggleDropdown dropdown |> T.send, Ports.runDatabaseQuery (dbPrefix ++ "/" ++ String.fromInt model.id ++ "/" ++ column.pathStr) dbSrc.db.url sqlQuery ] )
                    )

            else
                ( model, toggleDropdown dropdown |> Extra.msg )

        GotIncomingRows column result ->
            let
                linkedBy : Dict TableId (List RowPrimaryKey)
                linkedBy =
                    result.result |> Result.fold (\_ -> Dict.empty) (.rows >> List.head >> Maybe.mapOrElse (Dict.mapBoth TableId.parse parsePks) Dict.empty)
            in
            ( model |> mapState (mapSuccess (mapColumns (List.mapBy .path column (\c -> { c | linkedBy = linkedBy }))))
            , result.result |> Result.fold (\err -> "Can't get incoming rows: " ++ err |> Toasts.error |> showToast |> Extra.msg) (\_ -> Extra.none)
            )


withDbSource : String -> (Toasts.Msg -> msg) -> List Source -> Model -> (DbSourceInfoWithUrl -> ( Model, Extra msg )) -> ( Model, Extra msg )
withDbSource action showToast sources model f =
    (sources |> List.findBy .id model.source |> Result.fromMaybe ("source missing (" ++ SourceId.toString model.source ++ ")") |> Result.andThen DbSourceInfoWithUrl.fromSource)
        |> Result.fold (\err -> ( model, "Can't " ++ action ++ ", " ++ err |> Toasts.warning |> showToast |> Extra.msg )) f


parsePks : DbValue -> List RowPrimaryKey
parsePks value =
    case value of
        DbArray rows ->
            rows
                |> List.filterMap
                    (\row ->
                        case row of
                            DbObject dict ->
                                dict |> Dict.toList |> List.map (\( k, v ) -> { column = ColumnPath.fromString k, value = v }) |> Nel.fromList

                            _ ->
                                Nothing
                    )

        _ ->
            []


canBroadcast : Msg -> Bool
canBroadcast msg =
    -- send message from one table row to all other selected ones if True
    case msg of
        GotResult _ ->
            False

        ToggleIncomingRows _ _ _ ->
            False

        GotIncomingRows _ _ ->
            False

        _ ->
            True


mapStateLoading : (TableRow.LoadingState -> State) -> TableRow -> TableRow
mapStateLoading f row =
    case row.state of
        StateLoading s ->
            { row | state = f s }

        _ ->
            row


mapStateLoadingTM : (TableRow.LoadingState -> ( State, Maybe a )) -> TableRow -> ( TableRow, Maybe a )
mapStateLoadingTM f row =
    case row.state of
        StateLoading s ->
            f s |> Tuple.mapFirst (\res -> { row | state = res })

        _ ->
            ( row, Nothing )


mapLoading : (TableRow.LoadingState -> TableRow.LoadingState) -> State -> State
mapLoading f state =
    case state of
        StateLoading s ->
            StateLoading (f s)

        _ ->
            state


mapFailure : (TableRow.FailureState -> TableRow.FailureState) -> State -> State
mapFailure f state =
    case state of
        StateFailure s ->
            StateFailure (f s)

        _ ->
            state


mapSuccess : (TableRow.SuccessState -> TableRow.SuccessState) -> State -> State
mapSuccess f state =
    case state of
        StateSuccess s ->
            StateSuccess (f s)

        _ ->
            state


defaultHidden : { a | columns : List { b | pathStr : ColumnPathStr } } -> Set ColumnPathStr
defaultHidden res =
    res.columns |> List.drop 10 |> List.map .pathStr |> Set.fromList



-- VIEW


view : (Msg -> msg) -> (String -> msg) -> (HtmlId -> msg) -> (HtmlId -> msg) -> (Html msg -> PointerEvent -> msg) -> (HtmlId -> Bool -> msg) -> (TableId -> msg) -> (TableRowHover -> Bool -> msg) -> (RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> msg) -> msg -> (TableId -> Maybe ColumnPath -> msg) -> (Maybe SourceId -> Maybe SqlQueryOrigin -> msg) -> Time.Posix -> Platform -> ErdConf -> SchemaName -> HtmlId -> HtmlId -> HtmlId -> Erd -> Maybe DbSource -> Maybe ErdTable -> List ErdRelation -> Maybe TableMeta -> Maybe TableRowHover -> List TableRowRelation -> Color -> TableRow -> Html msg
view wrap noop toggleDropdown openPopover createContextMenu selectItem showTable hover showTableRow delete openNotes openDataExplorer now platform conf defaultSchema openedDropdown openedPopover htmlId erd source erdTable erdRelations tableMeta hoverRow rowRelations color row =
    let
        table : Maybe Table
        table =
            source |> Maybe.andThen (.tables >> Dict.get row.table)

        relations : List Relation
        relations =
            source |> Maybe.mapOrElse (.relations >> List.filter (\r -> r.src.table == row.table || r.ref.table == row.table)) []
    in
    div
        ([ id htmlId
         , class "max-w-xs bg-white text-default-500 text-xs border"
         , classList
            [ ( Tw.batch [ "ring-2", Tw.ring_300 color ], row.selected )
            , ( "shadow-md", (hoverRow |> Maybe.map Tuple.first) == Just row.id )
            ]
         ]
            ++ Bool.cond conf.hover [ onMouseEnter (hover ( row.id, Nothing ) True), onMouseLeave (hover ( row.id, Nothing ) False) ] []
        )
        [ viewHeader wrap noop toggleDropdown createContextMenu selectItem showTable delete openNotes platform conf defaultSchema openedDropdown (htmlId ++ "-header") color erdTable table tableMeta row
        , if row.collapsed then
            div [] []

          else
            case row.state of
                StateLoading s ->
                    viewLoading wrap delete s

                StateFailure s ->
                    viewFailure wrap delete s

                StateSuccess s ->
                    viewSuccess wrap noop openPopover createContextMenu hover showTableRow openNotes openDataExplorer platform conf defaultSchema openedDropdown openedPopover (htmlId ++ "-body") hoverRow erd source table erdTable relations erdRelations tableMeta rowRelations color row s
        , if row.collapsed then
            div [] []

          else
            viewFooter now source row
        ]


viewHeader : (Msg -> msg) -> (String -> msg) -> (HtmlId -> msg) -> (Html msg -> PointerEvent -> msg) -> (HtmlId -> Bool -> msg) -> (TableId -> msg) -> msg -> (TableId -> Maybe ColumnPath -> msg) -> Platform -> ErdConf -> SchemaName -> HtmlId -> HtmlId -> Color -> Maybe ErdTable -> Maybe Table -> Maybe TableMeta -> TableRow -> Html msg
viewHeader wrap noop toggleDropdown createContextMenu selectItem showTable delete openNotes platform conf defaultSchema openedDropdown htmlId color erdTable table tableMeta row =
    let
        comment : Maybe String
        comment =
            (table |> Maybe.andThen .comment |> Maybe.map .text) |> Maybe.orElse (erdTable |> Maybe.andThen .comment |> Maybe.map .text)

        notes : Maybe Notes
        notes =
            tableMeta |> Maybe.andThen .notes

        dropdownId : HtmlId
        dropdownId =
            htmlId ++ "-settings"

        dropdown : Html msg
        dropdown =
            TableRowContextMenu.view (wrap Refresh) openNotes (SetCollapsed >> wrap) delete platform conf defaultSchema row notes

        tableLabel : String
        tableLabel =
            TableId.show defaultSchema row.table

        filter : String
        filter =
            row.primaryKey |> Nel.toList |> List.map (.value >> DbValue.toString) |> String.join "/"
    in
    div
        [ css [ "p-2 flex items-center border-b border-gray-200 cursor-pointer", Tw.bg_50 color ] ]
        [ div
            ([ title (tableLabel ++ ": " ++ filter), class "flex flex-grow truncate" ]
                ++ Bool.cond conf.layout [ onContextMenu (createContextMenu dropdown) platform ] []
            )
            [ Bool.cond conf.layout (button [ onClick (showTable row.table), title ("Show table: " ++ tableLabel), css [ Tw.text_500 color, "mr-1 opacity-50" ] ] [ Icon.solid Icon.Eye "w-3 h-3 inline" ]) (text "")
            , comment |> Maybe.mapOrElse (\c -> span [ title c, css [ Tw.text_500 color, "mr-1 opacity-50" ] ] [ Icon.outline Icons.comment "w-3 h-3 inline" ]) (text "")
            , notes |> Maybe.mapOrElse (\n -> button [ type_ "button", onClick (openNotes row.table Nothing), title n, css [ Tw.text_500 color, "mr-1 opacity-50" ] ] [ Icon.outline Icons.notes "w-3 h-3 inline" ]) (text "")
            , span ([ class "flex-grow text-left truncate" ] ++ Bool.cond conf.select [ onPointerUp (\e -> Bool.cond (e.button == MainButton) (selectItem (TableRow.toHtmlId row.id) (e.ctrl || e.shift)) (noop "")) platform ] [])
                [ span [ css [ Tw.text_500 color, "font-bold" ] ] [ text tableLabel ], text (": " ++ filter) ]
            ]
        , if conf.layout then
            Dropdown.dropdown { id = dropdownId, direction = BottomLeft, isOpen = openedDropdown == dropdownId }
                (\m ->
                    button
                        [ type_ "button"
                        , id m.id
                        , onClick (toggleDropdown m.id)
                        , ariaExpanded m.isOpen
                        , ariaHaspopup "true"
                        , css [ "flex text-sm opacity-25", focus [ "outline-none" ] ]
                        ]
                        [ span [ class "sr-only" ] [ text "Open table settings" ]
                        , Icon.solid Icon.DotsVertical "w-4 h-4"
                        ]
                )
                (\_ -> dropdown)

          else
            text ""
        ]


viewLoading : (Msg -> msg) -> msg -> TableRow.LoadingState -> Html msg
viewLoading wrap delete res =
    div [ class "p-3" ]
        [ p [ class "text-sm font-semibold text-gray-900" ] [ Icon.loading "mr-2 inline animate-spin", text "Loading..." ]
        , viewQuery "mt-2 px-3 py-2 text-sm" res.query
        , div [ class "mt-6 flex justify-around" ]
            [ Button.white1 Tw.indigo [ onClick (Cancel |> wrap), title "Cancel fetching data" ] [ text "Cancel" ]
            , res.previous |> Maybe.map (\p -> Button.white1 Tw.emerald [ onClick (StateSuccess p |> SetState |> wrap), title "Restore previous data" ] [ text "Restore" ]) |> Maybe.withDefault (text "")
            , Button.white1 Tw.red [ onClick delete, title "Remove this row" ] [ text "Delete" ]
            ]
        ]


viewFailure : (Msg -> msg) -> msg -> TableRow.FailureState -> Html msg
viewFailure wrap delete res =
    div [ class "p-3" ]
        [ p [ class "text-sm font-semibold text-gray-900" ] [ text "Error" ]
        , div [ class "mt-1 px-6 py-4 block overflow-x-auto rounded bg-red-50 border border-red-200" ] [ text res.error ]
        , p [ class "mt-3 text-sm font-semibold text-gray-900" ] [ text "SQL" ]
        , viewQuery "mt-1 px-3 py-2" res.query
        , div [ class "mt-6 flex justify-around" ]
            [ Button.white1 Tw.indigo [ onClick (Refresh |> wrap), title "Retry fetching data" ] [ text "Refresh" ]
            , res.previous |> Maybe.map (\p -> Button.white1 Tw.emerald [ onClick (StateSuccess p |> SetState |> wrap), title "Restore previous data" ] [ text "Restore" ]) |> Maybe.withDefault (text "")
            , Button.white1 Tw.red [ onClick delete, title "Remove this row" ] [ text "Delete" ]
            ]
        ]


viewSuccess : (Msg -> msg) -> (String -> msg) -> (HtmlId -> msg) -> (Html msg -> PointerEvent -> msg) -> (TableRowHover -> Bool -> msg) -> (RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> (Maybe SourceId -> Maybe SqlQueryOrigin -> msg) -> Platform -> ErdConf -> SchemaName -> HtmlId -> HtmlId -> HtmlId -> Maybe TableRowHover -> Erd -> Maybe DbSource -> Maybe Table -> Maybe ErdTable -> List Relation -> List ErdRelation -> Maybe TableMeta -> List TableRowRelation -> Color -> TableRow -> TableRow.SuccessState -> Html msg
viewSuccess wrap noop openPopover createContextMenu hover showTableRow openNotes openDataExplorer platform conf defaultSchema openedDropdown openedPopover htmlId hoverRow erd source table erdTable relations erdRelations tableMeta rowRelations color row res =
    let
        ( hiddenValues, values ) =
            res.columns |> List.partition (\v -> row.hidden |> Set.member v.pathStr)

        hasHiddenValues : Bool
        hasHiddenValues =
            hiddenValues |> List.isEmpty |> not
    in
    div []
        [ Keyed.node "dl" [ class "divide-y divide-gray-200" ] (values |> List.map (\v -> ( v.pathStr, viewColumnRow wrap noop createContextMenu hover showTableRow openNotes openDataExplorer platform conf defaultSchema openedDropdown (htmlId ++ "-" ++ v.pathStr) hoverRow erd source table erdTable relations erdRelations tableMeta rowRelations color row v False )))
        , if hasHiddenValues then
            let
                popoverId : HtmlId
                popoverId =
                    htmlId ++ "-hidden-values-popover"

                showPopover : Bool
                showPopover =
                    not row.showHiddenColumns && openedPopover == popoverId

                popover : Html msg
                popover =
                    if showPopover then
                        Keyed.node "dl" [ class "divide-y divide-gray-200 shadow-md" ] (hiddenValues |> List.map (\v -> ( v.pathStr, viewColumnRow wrap noop createContextMenu hover showTableRow openNotes openDataExplorer platform conf defaultSchema openedDropdown (htmlId ++ "-" ++ v.pathStr) hoverRow erd source table erdTable relations erdRelations tableMeta rowRelations color row v True )))

                    else
                        div [] []
            in
            div []
                [ div
                    ([ class "px-2 py-1 font-medium border-t border-gray-200 opacity-50 hover:opacity-75"
                     , classList [ ( "cursor-pointer", conf.layout ) ]
                     ]
                        ++ Bool.cond conf.hover [ onMouseEnter (openPopover popoverId), onMouseLeave (openPopover "") ] []
                        ++ Bool.cond conf.layout [ onClick (ToggleHiddenColumns |> wrap) ] []
                    )
                    [ text ("... " ++ (hiddenValues |> String.pluralizeL " more column")) ]
                    |> Popover.r popover showPopover
                , if row.showHiddenColumns then
                    Keyed.node "dl" [ class "divide-y divide-gray-200 border-t border-gray-200 opacity-50" ] (hiddenValues |> List.map (\v -> ( v.pathStr, viewColumnRow wrap noop createContextMenu hover showTableRow openNotes openDataExplorer platform conf defaultSchema openedDropdown (htmlId ++ "-" ++ v.pathStr) hoverRow erd source table erdTable relations erdRelations tableMeta rowRelations color row v True )))

                  else
                    dl [] []
                ]

          else
            div [] []
        ]


viewColumnRow : (Msg -> msg) -> (String -> msg) -> (Html msg -> PointerEvent -> msg) -> (TableRowHover -> Bool -> msg) -> (RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> (Maybe SourceId -> Maybe SqlQueryOrigin -> msg) -> Platform -> ErdConf -> SchemaName -> HtmlId -> HtmlId -> Maybe TableRowHover -> Erd -> Maybe DbSource -> Maybe Table -> Maybe ErdTable -> List Relation -> List ErdRelation -> Maybe TableMeta -> List TableRowRelation -> Color -> TableRow -> TableRowColumn -> Bool -> Html msg
viewColumnRow wrap noop createContextMenu hover showTableRow openNotes openDataExplorer platform conf defaultSchema openedDropdown htmlId hoverRow erd source table erdTable relations erdRelations tableMeta rowRelations color row rowColumn hidden =
    let
        erdColumn : Maybe ErdColumn
        erdColumn =
            erdTable |> Maybe.andThen (ErdTable.getColumnI rowColumn.path)

        column : Maybe Column
        column =
            table |> Maybe.andThen (\t -> t.columns |> Dict.get rowColumn.pathStr)

        comment : Maybe String
        comment =
            (column |> Maybe.andThen .comment |> Maybe.map .text) |> Maybe.orElse (erdColumn |> Maybe.andThen .comment |> Maybe.map .text)

        meta : Maybe ColumnMeta
        meta =
            tableMeta |> Maybe.andThen (\m -> m.columns |> Dict.get rowColumn.pathStr)

        notes : Maybe Notes
        notes =
            meta |> Maybe.andThen .notes

        linkTo : Maybe DbColumnRef
        linkTo =
            if rowColumn.value == DbNull then
                Nothing

            else
                (relations |> List.find (\r -> r.src.table == row.table && r.src.column == rowColumn.path) |> Maybe.map2 (\s r -> { source = s.id, table = r.ref.table, column = r.ref.column }) source)
                    |> Maybe.orElse
                        (erdRelations
                            |> List.find (\r -> r.src.table == row.table && r.src.column == rowColumn.path)
                            |> Maybe.map2
                                (\s r ->
                                    { source = erd.tables |> TableId.dictGetI r.ref.table |> Maybe.andThen (ErdTable.getColumnI r.ref.column) |> Maybe.mapOrElse .origins [] |> ErdOrigin.query s.id
                                    , table = r.ref.table
                                    , column = r.ref.column
                                    }
                                )
                                source
                        )

        linkedBy : Dict TableId IncomingRowsQuery
        linkedBy =
            if rowColumn.value == DbNull then
                Dict.empty

            else
                -- TODO: use erdRelations for incoming rows from other sources? (could be nice but strange if the same db from several envs are added)
                relations
                    |> List.filter (\r -> r.ref.table == row.table && r.ref.column == rowColumn.path)
                    |> List.map .src
                    |> List.groupBy .table
                    |> Dict.filterMap
                        (\id cols ->
                            source
                                |> Maybe.andThen (.tables >> Dict.get id)
                                |> Maybe.andThen
                                    (\t ->
                                        t.primaryKey
                                            |> Maybe.map
                                                (\pk ->
                                                    { primaryKey = pk.columns |> Nel.map (\c -> ( c, t |> Table.getColumnI c |> Maybe.mapOrElse .kind "" ))
                                                    , foreignKeys = cols |> List.map (\c -> ( c.column, t |> Table.getColumnI c.column |> Maybe.mapOrElse .kind "" ))
                                                    , altCols = t |> Table.getAltColumns
                                                    }
                                                )
                                    )
                        )

        isColumn : TableRowRelationColumn -> Bool
        isColumn c =
            c.row.id == row.id && c.column.path == rowColumn.path

        isHover : TableRowRelationColumn -> TableRowHover -> Bool
        isHover c h =
            h == ( c.row.id, Just c.column.path )

        highlight : Bool
        highlight =
            hoverRow |> Maybe.any (\h -> h == ( row.id, Just rowColumn.path ) || (rowRelations |> List.any (\r -> (isColumn r.src && isHover r.ref h) || (isColumn r.ref && isHover r.src h))))

        dropdownId : HtmlId
        dropdownId =
            htmlId ++ "-dropdown"
    in
    div
        ([ css
            [ "px-2 py-1 flex font-medium"
            , if highlight then
                Tw.batch [ Tw.text_500 color, Tw.bg_50 color ]

              else
                "text-default-500 bg-white"
            ]
         ]
            ++ Bool.cond conf.hover [ onMouseEnter (hover ( row.id, Just rowColumn.path ) True), onMouseLeave (hover ( row.id, Just rowColumn.path ) False) ] []
            ++ Bool.cond conf.layout
                [ onDblClick (\_ -> rowColumn.pathStr |> Bool.cond hidden ShowColumn HideColumn |> wrap) platform
                , onContextMenu (createContextMenu (Bool.cond hidden (ColumnRowContextMenu.viewHidden (ShowColumn >> wrap)) (ColumnRowContextMenu.view (HideColumn >> wrap)) openNotes platform row rowColumn notes)) platform
                ]
                []
        )
        [ dt [ class "whitespace-pre" ]
            [ text (ColumnPath.show rowColumn.path)
            , comment |> Maybe.mapOrElse (\c -> span [ title c, class "ml-1 opacity-50" ] [ Icon.outline Icons.comment "w-3 h-3 inline" ]) (text "")
            , notes |> Maybe.mapOrElse (\n -> button [ type_ "button", onClick (openNotes row.table (Just rowColumn.path)), title n, class "ml-1 opacity-50" ] [ Icon.outline Icons.notes "w-3 h-3 inline" ]) (text "")
            ]
        , dd [ title (DbValue.toString rowColumn.value), class "ml-3 flex-grow text-right opacity-50 truncate" ]
            [ text (DbValue.toString rowColumn.value)
            ]
        , linkTo
            |> Maybe.map
                (\r ->
                    if conf.layout then
                        button
                            [ type_ "button"

                            -- TODO: handle composite pk, needs composite fk before (also handle polymorphic relations)
                            , onClick (showTableRow { source = r.source, table = r.table, primaryKey = Nel { column = r.column, value = rowColumn.value } [] } Nothing (Just (PositionHint.PlaceRight row.position row.size)))
                            , title "See linked row"
                            , class "ml-1 opacity-50"
                            ]
                            [ Icon.solid Icon.ExternalLink "w-3 h-3 inline" ]

                    else
                        button [ type_ "button", class "ml-1 opacity-50 cursor-default" ] [ Icon.solid Icon.ExternalLink "w-3 h-3 inline" ]
                )
            |> Maybe.withDefault (text "")
        , source
            |> Maybe.filter (\_ -> Dict.nonEmpty linkedBy)
            |> Maybe.map DbSource.toInfo
            |> Maybe.mapOrElse
                (\s ->
                    if conf.layout then
                        Dropdown.dropdown { id = dropdownId, direction = BottomLeft, isOpen = openedDropdown == dropdownId }
                            (\m ->
                                button
                                    [ type_ "button"
                                    , id m.id
                                    , onClick (ToggleIncomingRows m.id rowColumn linkedBy |> wrap)
                                    , title "See rows linking this"
                                    , ariaExpanded m.isOpen
                                    , ariaHaspopup "true"
                                    , css [ "ml-1 opacity-50", focus [ "outline-none" ] ]
                                    ]
                                    [ span [ class "sr-only" ] [ text "Incoming rows" ]
                                    , Icon.solid Icon.Login "w-3 h-3"
                                    ]
                            )
                            (\_ ->
                                div []
                                    (linkedBy
                                        |> Dict.toList
                                        |> List.map
                                            (\( tableId, query ) ->
                                                rowColumn.linkedBy
                                                    |> Dict.get tableId
                                                    |> Maybe.map (\linkedRows -> viewColumnRowIncomingRows noop showTableRow openDataExplorer defaultSchema s tableId row rowColumn query linkedRows)
                                                    |> Maybe.withDefault (ContextMenu.btnSubmenu { label = TableId.show defaultSchema tableId ++ " (?)", content = ContextMenu.Simple { action = noop "table-row-column-linked-rows-not-loaded" } })
                                            )
                                    )
                            )

                    else
                        div [] [ button [ type_ "button", class "ml-1 opacity-50 cursor-default" ] [ Icon.solid Icon.Login "w-3 h-3" ] ]
                )
                (text "")
        ]


viewColumnRowIncomingRows : (String -> msg) -> (RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> msg) -> (Maybe SourceId -> Maybe SqlQueryOrigin -> msg) -> SchemaName -> DbSourceInfo -> TableId -> TableRow -> TableRowColumn -> IncomingRowsQuery -> List RowPrimaryKey -> Html msg
viewColumnRowIncomingRows noop showTableRow openDataExplorer defaultSchema source tableId row rowColumn query linkedRows =
    ContextMenu.btnSubmenu
        { label = TableId.show defaultSchema tableId ++ " (" ++ (linkedRows |> List.length |> (\len -> String.fromInt len ++ Bool.cond (len == DbQuery.incomingRowsLimit) "+" "")) ++ ")"
        , content =
            if linkedRows |> List.isEmpty then
                ContextMenu.Simple { action = noop "table-row-column-no-linked-rows" }

            else
                ContextMenu.SubMenu
                    (linkedRows
                        |> List.map
                            (\r ->
                                { label = formatIncomingRowsLabel r
                                , action = showTableRow { source = source.id, table = tableId, primaryKey = r |> RowPrimaryKey.extractAlt |> Tuple.first } Nothing (Just (PositionHint.PlaceRight row.position row.size))
                                }
                            )
                        |> List.insert { label = "See all", action = openDataExplorer (Just source.id) (Just (DbQuery.filterTable source.db.kind { table = tableId, filters = query.foreignKeys |> List.map (\( fk, _ ) -> TableFilter DbOr fk DbEqual rowColumn.value) })) }
                    )
                    ContextMenu.BottomRight
        }


formatIncomingRowsLabel : RowPrimaryKey -> String
formatIncomingRowsLabel r =
    let
        ( pk, alt ) =
            r |> RowPrimaryKey.extractAlt

        key : String
        key =
            if pk.tail |> List.isEmpty then
                pk.head.value |> DbValue.toString

            else
                pk |> Nel.toList |> List.map (\v -> (v.column |> Nel.toList |> String.join ".") ++ ": " ++ (v.value |> DbValue.toString)) |> String.join ", "
    in
    alt |> Maybe.map (\a -> (a |> DbValue.toString) ++ " (" ++ (key |> String.ellipsis 12) ++ ")") |> Maybe.withDefault key


viewQuery : TwClass -> SqlQueryOrigin -> Html msg
viewQuery classes query =
    div [ css [ "block overflow-x-auto rounded bg-gray-50 border border-gray-200", classes ] ] [ text query.sql ]


viewFooter : Time.Posix -> Maybe DbSource -> TableRow -> Html msg
viewFooter now source row =
    let
        time : Time.Posix
        time =
            case row.state of
                StateLoading s ->
                    s.startedAt

                StateFailure s ->
                    s.failedAt

                StateSuccess s ->
                    s.loadedAt
    in
    div [ class "px-3 py-1 bg-default-50 text-right italic border-t border-gray-200" ]
        [ text "from "
        , source |> Maybe.mapOrElse (\s -> text s.name) (span [ title (SourceId.toString row.source) ] [ text "unknown source" ])
        , text ", "
        , span [ title (DateTime.toIso time) ] [ text (DateTime.human now time) ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | tableRowDocState : DocState }


type alias DocState =
    { openedDropdown : HtmlId
    , openedPopover : HtmlId
    , tableRowHover : Maybe TableRowHover
    , user : Model
    , event : Model
    , failure : Model
    , loading : Model
    }


docInit : DocState
docInit =
    { openedDropdown = ""
    , openedPopover = ""
    , tableRowHover = Nothing
    , user = docSuccessUser
    , event = docSuccessEvent
    , failure = docFailure
    , loading = docLoading
    }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "TableRow"
        |> Chapter.renderStatefulComponentList
            [ ( "table row"
              , \{ tableRowDocState } ->
                    div [ class "p-3 bg-gray-100 flex items-start space-x-3" ]
                        [ docView tableRowDocState .user (\s m -> { s | user = m }) "table-row-users"
                        , docView tableRowDocState .event (\s m -> { s | event = m }) "table-row-event"
                        ]
              )
            , ( "error"
              , \{ tableRowDocState } ->
                    div [ class "p-3 bg-gray-100 flex items-start space-x-3" ]
                        [ docView tableRowDocState .failure (\s m -> { s | failure = m }) "table-row-failure"
                        , docView tableRowDocState (.failure >> mapState (mapFailure (setPrevious (TableRow.stateSuccess docSuccessUser)))) (\s m -> { s | failure = m }) "table-row-failure-with-previous"
                        ]
              )
            , ( "loading"
              , \{ tableRowDocState } ->
                    div [ class "p-3 bg-gray-100 flex items-start space-x-3" ]
                        [ docView tableRowDocState .loading (\s m -> { s | loading = m }) "table-row-loading"
                        , docView tableRowDocState (.loading >> mapState (mapLoading (setPrevious (TableRow.stateSuccess docSuccessUser)))) (\s m -> { s | loading = m }) "table-row-loading-with-previous"
                        ]
              )
            ]


docView : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> HtmlId -> Html (ElmBook.Msg (SharedDocState x))
docView s get set htmlId =
    view (docUpdate s get set) docNoop (docToggleDropdown s) (docOpenPopover s) docCreateContextMenu (docSelectItem s get set) docShowTable (docHoverTableRow s) docShowTableRow docDelete docOpenNotes docOpenDataExplorer docNow docPlatform docErdConf docDefaultSchema s.openedDropdown s.openedPopover htmlId docErd (docSource |> DbSource.fromSource) docErdTable [] docTableMeta s.tableRowHover [] Tw.indigo (get s)


docSuccessUser : TableRow
docSuccessUser =
    { id = 1
    , positionHint = Nothing
    , position = Position.zeroGrid
    , size = Size.zeroCanvas
    , source = SourceId.zero
    , table = ( "public", "users" )
    , primaryKey = Nel { column = Nel "id" [], value = DbString "11bd9544-d56a-43d7-9065-6f1f25addf8a" } []
    , state =
        StateSuccess
            { columns =
                [ docTableRowColumn "id" (DbString "11bd9544-d56a-43d7-9065-6f1f25addf8a")
                , docTableRowColumn "slug" (DbString "loicknuchel")
                , docTableRowColumn "name" (DbString "Loïc Knuchel")
                , docTableRowColumn "email" (DbString "loicknuchel@gmail.com")
                , docTableRowColumn "provider" (DbString "github")
                , docTableRowColumn "provider_uid" (DbString "653009")
                , docTableRowColumn "avatar" (DbString "https://avatars.githubusercontent.com/u/653009?v=4")
                , docTableRowColumn "github_username" (DbString "loicknuchel")
                , docTableRowColumn "twitter_username" (DbString "loicknuchel")
                , docTableRowColumn "is_admin" (DbBool True)
                , docTableRowColumn "hashed_password" DbNull
                , docTableRowColumn "last_signin" (DbString "2023-04-27 17:55:11.582485")
                , docTableRowColumn "created_at" (DbString "2023-04-27 17:55:11.612429")
                , docTableRowColumn "updated_at" (DbString "2023-07-19 20:57:53.438550")
                , docTableRowColumn "confirmed_at" (DbString "2023-04-27 17:55:11.582485")
                , docTableRowColumn "deleted_at" DbNull
                , docTableRowColumn "data" (DbObject (Dict.fromList [ ( "attributed_to", DbNull ), ( "attributed_from", DbNull ) ]))
                , docTableRowColumn "onboarding" DbNull
                , docTableRowColumn "provider_data" (DbObject (Dict.fromList [ ( "id", DbInt 653009 ), ( "bio", DbString "Principal engineer at Doctolib" ), ( "blog", DbString "https://loicknuchel.fr" ), ( "plan", DbObject (Dict.fromList [ ( "name", DbString "free" ) ]) ) ]))
                ]
            , startedAt = Time.millisToPosix 1690964408438
            , loadedAt = Time.millisToPosix 1690964408438
            }
    , hidden = Set.fromList [ "provider", "provider_uid", "last_signin", "created_at", "updated_at", "confirmed_at", "deleted_at", "hashed_password" ]
    , showHiddenColumns = False
    , selected = False
    , collapsed = False
    }


docSuccessEvent : TableRow
docSuccessEvent =
    { id = 2
    , positionHint = Nothing
    , position = Position.zeroGrid
    , size = Size.zeroCanvas
    , source = docSource.id
    , table = ( "public", "events" )
    , primaryKey = Nel { column = Nel "id" [], value = DbString "dcecf4fe-aa35-44fb-a90c-eba7d2103f4e" } []
    , state =
        StateSuccess
            { columns =
                [ docTableRowColumn "id" (DbString "dcecf4fe-aa35-44fb-a90c-eba7d2103f4e")
                , docTableRowColumn "name" (DbString "editor_source_created")
                , docTableRowColumn "data" DbNull
                , docTableRowColumn "details" (DbObject (Dict.fromList [ ( "kind", DbString "DatabaseConnection" ), ( "format", DbString "database" ), ( "nb_table", DbInt 12 ), ( "nb_relation", DbInt 25 ) ]))
                , docTableRowColumn "created_by" (DbString "11bd9544-d56a-43d7-9065-6f1f25addf8a")
                , docTableRowColumn "created_at" (DbString "2023-04-29 15:25:40.659800")
                , docTableRowColumn "organization_id" (DbString "2d803b04-90d7-4e05-940f-5e887470b595")
                , docTableRowColumn "project_id" (DbString "a2cf8a87-0316-40eb-98ce-72659dae9420")
                ]
            , startedAt = Time.millisToPosix 1691079663421
            , loadedAt = Time.millisToPosix 1691079663421
            }
    , hidden = Set.fromList []
    , showHiddenColumns = False
    , selected = False
    , collapsed = False
    }


docLoading : TableRow
docLoading =
    { id = 3
    , positionHint = Nothing
    , position = Position.zeroGrid
    , size = Size.zeroCanvas
    , source = docSource.id
    , table = ( "public", "events" )
    , primaryKey = Nel { column = Nel "id" [], value = DbString "dcecf4fe-aa35-44fb-a90c-eba7d2103f4e" } []
    , state = StateLoading { query = { sql = "SELECT * FROM public.events WHERE id='dcecf4fe-aa35-44fb-a90c-eba7d2103f4e';", origin = "doc", db = DatabaseKind.default }, startedAt = Time.millisToPosix 1691079663421, previous = Nothing }
    , hidden = Set.fromList []
    , showHiddenColumns = False
    , selected = False
    , collapsed = False
    }


docFailure : TableRow
docFailure =
    { id = 4
    , positionHint = Nothing
    , position = Position.zeroGrid
    , size = Size.zeroCanvas
    , source = docSource.id
    , table = ( "public", "events" )
    , primaryKey = Nel { column = Nel "id" [], value = DbString "dcecf4fe-aa35-44fb-a90c-eba7d2103f4e" } []
    , state = StateFailure { query = { sql = "SELECT * FROM public.event WHERE id='dcecf4fe-aa35-44fb-a90c-eba7d2103f4e';", origin = "doc", db = DatabaseKind.default }, error = "relation \"public.event\" does not exist", startedAt = Time.millisToPosix 1691079663421, failedAt = Time.millisToPosix 1691079663421, previous = Nothing }
    , hidden = Set.fromList []
    , showHiddenColumns = False
    , selected = False
    , collapsed = False
    }


docTableRowColumn : ColumnPathStr -> DbValue -> TableRowColumn
docTableRowColumn pathStr value =
    { path = ColumnPath.fromString pathStr, pathStr = pathStr, value = value, linkedBy = Dict.empty }


docNow : Time.Posix
docNow =
    Time.millisToPosix 1691079793039


docPlatform : Platform
docPlatform =
    Platform.PC


docErdConf : ErdConf
docErdConf =
    ErdConf.project Nothing UserRole.Owner


docDefaultSchema : SchemaName
docDefaultSchema =
    "public"


docSource : Source
docSource =
    { id = SourceId.one
    , name = "azimutt_dev"
    , kind = DatabaseConnection { kind = PostgreSQL, url = Just "postgresql://postgres:postgres@localhost:5432/azimutt_dev", storage = DatabaseUrlStorage.Project }
    , content = Array.empty
    , tables =
        [ docTable "public" "users" [ ( "id", "uuid", False ), ( "slug", "varchar", False ), ( "name", "varchar", False ), ( "email", "varchar", False ), ( "provider", "varchar", True ), ( "provider_uid", "varchar", True ), ( "avatar", "varchar", False ), ( "github_username", "varchar", True ), ( "twitter_username", "varchar", True ), ( "is_admin", "boolean", False ), ( "hashed_password", "varchar", True ), ( "last_signin", "timestamp", False ), ( "created_at", "timestamp", False ), ( "updated_at", "timestamp", False ), ( "confirmed_at", "timestamp", True ), ( "deleted_at", "timestamp", True ), ( "data", "json", False ), ( "onboarding", "json", False ), ( "provider_data", "json", True ), ( "tags", "varchar[]", False ) ]
        , docTable "public" "organizations" [ ( "id", "uuid", False ), ( "name", "varchar", False ), ( "data", "json", True ), ( "created_by", "uuid", True ), ( "created_at", "timestamp", False ) ]
        , docTable "public" "projects" [ ( "id", "uuid", False ), ( "organization_id", "uuid", False ), ( "slug", "varchar", False ), ( "name", "varchar", False ), ( "created_by", "uuid", True ), ( "created_at", "timestamp", False ) ]
        , docTable "public" "events" [ ( "id", "uuid", False ), ( "name", "varchar", False ), ( "data", "json", True ), ( "details", "json", True ), ( "created_by", "uuid", True ), ( "created_at", "timestamp", False ), ( "organization_id", "uuid", True ), ( "project_id", "uuid", True ) ]
        , docTable "public" "city" [ ( "id", "int", False ), ( "name", "varchar", False ), ( "country_code", "varchar", False ), ( "district", "varchar", False ), ( "population", "int", False ) ]
        ]
            |> Dict.fromListBy .id
    , relations =
        [ docRelation ( "public", "organizations", "created_by" ) ( "public", "users", "id" )
        , docRelation ( "public", "projects", "organization_id" ) ( "public", "organizations", "id" )
        , docRelation ( "public", "projects", "created_by" ) ( "public", "users", "id" )
        , docRelation ( "public", "events", "created_by" ) ( "public", "users", "id" )
        , docRelation ( "public", "events", "organization_id" ) ( "public", "organizations", "id" )
        , docRelation ( "public", "events", "project_id" ) ( "public", "projects", "id" )
        ]
    , types = Dict.empty
    , enabled = True
    , fromSample = Nothing
    , createdAt = Time.zero
    , updatedAt = Time.zero
    }


docErd : Erd
docErd =
    Project.create Nothing [] "Azimutt" docSource |> Erd.create


docErdTable : Maybe ErdTable
docErdTable =
    docErd.tables |> Dict.get ( "public", "users" )


docTableMeta : Maybe TableMeta
docTableMeta =
    Just
        { notes = Nothing
        , tags = []
        , columns = Dict.empty
        }


docTable : SchemaName -> TableName -> List ( ColumnName, ColumnType, Bool ) -> Table
docTable schema name columns =
    Table.empty
        |> (\t ->
                { t
                    | id = ( schema, name )
                    , schema = schema
                    , name = name
                    , columns = columns |> List.indexedMap (\i ( col, kind, nullable ) -> Column.empty |> (\c -> { c | index = i, name = col, kind = kind, nullable = nullable })) |> Dict.fromListBy .name
                    , primaryKey = Just { name = Just (name ++ "_pk"), columns = Nel (Nel "id" []) [] }
                }
           )


docRelation : ( SchemaName, TableName, ColumnName ) -> ( SchemaName, TableName, ColumnName ) -> Relation
docRelation ( fromSchema, fromTable, fromColumn ) ( toSchema, toTable, toColumn ) =
    Relation.new (fromTable ++ "." ++ fromColumn ++ "->" ++ toTable ++ "." ++ toColumn) { table = ( fromSchema, fromTable ), column = Nel fromColumn [] } { table = ( toSchema, toTable ), column = Nel toColumn [] }


docUpdate : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate s get set msg =
    s |> get |> update (\_ -> logAction "msg") (docToggleDropdown s) docShowToast docDelete docUnDelete Time.zero ProjectInfo.zero [ docSource ] s.openedDropdown msg |> Tuple.first |> set s |> docSetState


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | tableRowDocState = state })


docToggleDropdown : DocState -> HtmlId -> ElmBook.Msg (SharedDocState x)
docToggleDropdown s id =
    if s.openedDropdown == id then
        docSetState { s | openedDropdown = "" }

    else
        docSetState { s | openedDropdown = id }


docOpenPopover : DocState -> HtmlId -> ElmBook.Msg (SharedDocState x)
docOpenPopover s id =
    docSetState { s | openedPopover = id }


docHoverTableRow : DocState -> TableRowHover -> Bool -> ElmBook.Msg (SharedDocState x)
docHoverTableRow s hover on =
    if on then
        docSetState { s | tableRowHover = Just hover }

    else
        docSetState { s | tableRowHover = Nothing }


docNoop : String -> ElmBook.Msg state
docNoop _ =
    logAction "noop"


docCreateContextMenu : Html msg -> PointerEvent -> ElmBook.Msg state
docCreateContextMenu _ _ =
    logAction "createContextMenu"


docSelectItem : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> HtmlId -> Bool -> ElmBook.Msg (SharedDocState x)
docSelectItem s get set _ _ =
    s |> get |> mapSelected not |> set s |> docSetState


docShowTable : TableId -> ElmBook.Msg state
docShowTable _ =
    logAction "showTable"


docShowTableRow : RowQuery -> Maybe TableRow.SuccessState -> Maybe PositionHint -> ElmBook.Msg state
docShowTableRow _ _ _ =
    logAction "showTableRow"


docDelete : ElmBook.Msg state
docDelete =
    logAction "delete"


docUnDelete : TableRow -> ElmBook.Msg state
docUnDelete _ =
    logAction "unDelete"


docOpenNotes : TableId -> Maybe ColumnPath -> ElmBook.Msg state
docOpenNotes _ _ =
    logAction "openNotes"


docOpenDataExplorer : Maybe SourceId -> Maybe SqlQueryOrigin -> ElmBook.Msg state
docOpenDataExplorer _ _ =
    logAction "openDataExplorer"


docShowToast : Toasts.Msg -> ElmBook.Msg state
docShowToast _ =
    logAction "showToast"
