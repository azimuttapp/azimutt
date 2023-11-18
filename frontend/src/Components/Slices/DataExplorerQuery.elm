module Components.Slices.DataExplorerQuery exposing (DocState, FailureState, Id, Model, Msg(..), RowIndex, SharedDocState, State(..), SuccessState, doc, docCityQuery, docCitySuccess, docInit, docProjectsQuery, docProjectsSuccess, docRelation, docSource, docTable, docUsersQuery, docUsersSuccess, init, stateSuccess, update, view)

import Array
import Components.Atoms.Icon as Icon exposing (Icon)
import Components.Atoms.Icons as Icons
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Pagination as Pagination exposing (PageIndex)
import Components.Slices.DataExplorerStats as DataExplorerStats
import Components.Slices.DataExplorerValue as DataExplorerValue
import DataSources.DbMiner.DbTypes exposing (RowQuery)
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, input, p, pre, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, classList, id, name, placeholder, scope, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Encode as Encode
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.DatabaseKind as DatabaseKind
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Notes exposing (Notes)
import Libs.Nel exposing (Nel)
import Libs.Order as Order exposing (compareMaybe)
import Libs.Result as Result
import Libs.Set as Set
import Libs.String as String
import Libs.Tailwind exposing (TwClass, focus)
import Libs.Task as T
import Libs.Time as Time
import Models.DbSourceInfo as DbSourceInfo exposing (DbSourceInfo)
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Project.Column exposing (Column)
import Models.Project.ColumnMeta exposing (ColumnMeta)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.Comment exposing (Comment)
import Models.Project.Metadata exposing (Metadata)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.QueryResult as QueryResult exposing (QueryResult, QueryResultColumn, QueryResultColumnTarget, QueryResultRow, QueryResultSuccess)
import Models.SqlQuery exposing (SqlQuery, SqlQueryOrigin)
import Ports
import Services.Lenses exposing (mapState, setQuery, setState)
import Services.Toasts as Toasts
import Set exposing (Set)
import Time
import Track


type alias Model =
    { id : Id
    , source : DbSourceInfo
    , query : SqlQueryOrigin
    , state : State
    }


type alias Id =
    Int


type alias RowIndex =
    Int


type State
    = StateRunning
    | StateCanceled
    | StateFailure FailureState
    | StateSuccess SuccessState


type alias FailureState =
    { error : String, startedAt : Time.Posix, failedAt : Time.Posix }


type alias SuccessState =
    { columns : List QueryResultColumn
    , rows : List QueryResultRow
    , startedAt : Time.Posix
    , succeededAt : Time.Posix
    , page : Int
    , expanded : Set RowIndex
    , collapsed : Set ColumnPathStr
    , documentMode : Bool
    , showQuery : Bool
    , search : String
    , sortBy : Maybe String
    , fullScreen : Bool
    }


type Msg
    = Cancel
    | GotResult QueryResult
    | ChangePage Int
    | ExpandRow RowIndex
    | CollapseColumn ColumnPathStr
    | ToggleQuery
    | ToggleDocumentMode
    | ToggleFullScreen
    | UpdateSearch String
    | UpdateSort (Maybe String)
    | Refresh
    | ExportData String



-- INIT


dbPrefix : String
dbPrefix =
    "data-explorer-query"


init : ProjectInfo -> Id -> DbSourceInfo -> SqlQueryOrigin -> ( Model, Cmd msg )
init project id source query =
    ( { id = id, source = source, query = query, state = StateRunning }
    , Cmd.batch [ Ports.runDatabaseQuery (dbPrefix ++ "/" ++ String.fromInt id) source.db.url query, Track.dataExplorerQueryOpened source query project ]
    )


initFailure : Time.Posix -> Time.Posix -> String -> State
initFailure started finished err =
    StateFailure { error = err, startedAt = started, failedAt = finished }


initSuccess : Time.Posix -> Time.Posix -> QueryResultSuccess -> State
initSuccess started finished res =
    StateSuccess
        { columns = res.columns
        , rows = res.rows
        , startedAt = started
        , succeededAt = finished
        , page = 1
        , expanded = Set.empty
        , collapsed = Set.empty
        , documentMode = False
        , showQuery = False
        , search = ""
        , sortBy = Nothing
        , fullScreen = False
        }



-- UPDATE


update : (Toasts.Msg -> msg) -> ProjectInfo -> Msg -> Model -> ( Model, Cmd msg )
update showToast project msg model =
    case msg of
        Cancel ->
            ( model |> mapState (\_ -> StateCanceled), Cmd.none )

        GotResult res ->
            ( model |> setQuery res.query |> mapState (\_ -> res.result |> Result.fold (initFailure res.started res.finished) (initSuccess res.started res.finished)), Track.dataExplorerQueryResult res project )

        ChangePage p ->
            ( model |> mapState (mapSuccess (\s -> { s | page = p })), Cmd.none )

        ExpandRow i ->
            ( model |> mapState (mapSuccess (\s -> { s | expanded = s.expanded |> Set.toggle i })), Cmd.none )

        CollapseColumn pathStr ->
            ( model |> mapState (mapSuccess (\s -> { s | collapsed = s.collapsed |> Set.toggle pathStr })), Cmd.none )

        ToggleQuery ->
            ( model |> mapState (mapSuccess (\s -> { s | showQuery = not s.showQuery })), Cmd.none )

        ToggleDocumentMode ->
            ( model |> mapState (mapSuccess (\s -> { s | documentMode = not s.documentMode })), Cmd.none )

        ToggleFullScreen ->
            ( model |> mapState (mapSuccess (\s -> { s | fullScreen = not s.fullScreen })), Cmd.none )

        UpdateSearch search ->
            ( model |> mapState (mapSuccess (\s -> { s | search = search, page = 1 })), Cmd.none )

        UpdateSort sort ->
            ( model |> mapState (mapSuccess (\s -> { s | sortBy = sort, page = 1 })), Cmd.none )

        Refresh ->
            ( model |> setState StateRunning, Ports.runDatabaseQuery (dbPrefix ++ "/" ++ String.fromInt model.id) model.source.db.url model.query )

        ExportData extension ->
            case model.state of
                StateSuccess s ->
                    ( model, Ports.downloadFile (model |> fileName extension) (s |> fileContent extension) )

                _ ->
                    ( model, Toasts.warning "Can't export data not in success." |> showToast |> T.send )


stateSuccess : Model -> Maybe SuccessState
stateSuccess model =
    case model.state of
        StateSuccess s ->
            Just s

        _ ->
            Nothing


mapSuccess : (SuccessState -> SuccessState) -> State -> State
mapSuccess f state =
    case state of
        StateSuccess s ->
            StateSuccess (f s)

        _ ->
            state


fileName : String -> Model -> String
fileName extension model =
    model.source.name ++ "-results-" ++ String.fromInt model.id ++ "." ++ extension


fileContent : String -> SuccessState -> String
fileContent extension state =
    if extension == "json" then
        jsonFile state

    else
        csvFile state


jsonFile : SuccessState -> String
jsonFile state =
    (state.rows |> Encode.list QueryResult.encodeQueryResultRow |> Encode.encode 2) ++ "\n"


csvFile : SuccessState -> String
csvFile state =
    let
        separator : String
        separator =
            ","

        header : String
        header =
            state.columns |> List.map (.pathStr >> csvEscape) |> String.join separator

        rows : List String
        rows =
            state.rows |> List.map (\r -> state.columns |> List.map (\c -> r |> Dict.get c.pathStr |> Maybe.mapOrElse DbValue.toString "" |> csvEscape) |> String.join separator)
    in
    (header :: rows |> String.join "\n") ++ "\n"


csvEscape : String -> String
csvEscape value =
    let
        escaped : String
        escaped =
            value |> String.replace "\"" "\"\"" |> String.replace "\u{000D}" "\\r" |> String.replace "\n" "\\n"
    in
    if (value |> String.contains ",") || (value |> String.contains "\"") then
        "\"" ++ escaped ++ "\""

    else
        escaped



-- VIEW


view : (Msg -> msg) -> (HtmlId -> msg) -> ((msg -> String -> Html msg) -> msg) -> (DbSourceInfo -> RowQuery -> msg) -> msg -> (TableId -> Maybe ColumnPath -> msg) -> HtmlId -> SchemaName -> Maybe Source -> Metadata -> HtmlId -> Model -> Html msg
view wrap toggleDropdown openModal openRow deleteQuery openNotes openedDropdown defaultSchema source metadata htmlId model =
    case model.state of
        StateRunning ->
            viewCard False
                [ p [ class "text-sm font-semibold text-gray-900" ] [ text ("#" ++ String.fromInt model.id ++ " " ++ model.source.name) ]
                , p [ class "mt-1 text-sm text-gray-500 space-x-2" ]
                    [ span [ class "font-bold text-amber-500" ] [ text "Running..." ]
                    , span [ class "relative inline-flex h-2 w-2" ]
                        [ span [ class "animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75" ] []
                        , span [ class "relative inline-flex rounded-full h-2 w-2 bg-amber-500" ] []
                        ]

                    --, span [] [ text (String.fromInt (Time.posixToMillis now - Time.posixToMillis model.startedAt) ++ " ms") ]
                    ]
                ]
                (div [ class "mt-3" ] [ model.query |> viewQuery False ])
                (div [ class "relative flex space-x-1 text-left" ] [ viewActionButton Icon.XCircle "Cancel execution" (wrap Cancel) ])

        StateCanceled ->
            viewCard False
                [ p [ class "text-sm font-semibold text-gray-900" ] [ text ("#" ++ String.fromInt model.id ++ " " ++ model.source.name) ]
                , p [ class "mt-1 text-sm text-gray-500 space-x-2" ]
                    [ span [ class "font-bold" ] [ text "Canceled!" ]

                    --, span [] [ text (String.fromInt (Time.posixToMillis res.canceledAt - Time.posixToMillis model.startedAt) ++ " ms") ]
                    ]
                ]
                (div [ class "mt-3" ] [ model.query |> viewQuery False ])
                (div [ class "relative flex space-x-1 text-left" ] [ viewActionButton Icon.Trash "Delete" deleteQuery ])

        StateFailure res ->
            viewCard False
                [ p [ class "text-sm font-semibold text-gray-900" ] [ text ("#" ++ String.fromInt model.id ++ " " ++ model.source.name) ]
                , p [ class "mt-1 text-sm text-gray-500 space-x-1" ]
                    [ span [ class "font-bold text-red-500" ] [ text "Failed" ]
                    , span [] [ text (String.fromInt (Time.posixToMillis res.failedAt - Time.posixToMillis res.startedAt) ++ " ms") ]
                    ]
                ]
                (div []
                    [ p [ class "mt-3 text-sm font-semibold text-gray-900" ] [ text "Error" ]
                    , pre [ class "mt-1 px-6 py-4 block text-sm whitespace-pre overflow-x-auto rounded bg-red-50 border border-red-200" ] [ text res.error ]
                    , p [ class "mt-3 text-sm font-semibold text-gray-900" ] [ text "SQL" ]
                    , div [ class "mt-1" ] [ model.query |> viewQuery False ]
                    ]
                )
                (div [ class "relative flex space-x-1 text-left" ]
                    [ viewActionButton Icon.Refresh "Run again execution" (wrap Refresh)
                    , viewActionButton Icon.Trash "Delete" deleteQuery
                    ]
                )

        StateSuccess res ->
            let
                dropdownId : HtmlId
                dropdownId =
                    htmlId ++ "-settings"
            in
            viewCard res.fullScreen
                [ p [ class "text-sm text-gray-500 space-x-1" ]
                    [ span [ class "font-semibold text-gray-900" ] [ text ("#" ++ String.fromInt model.id ++ " " ++ model.source.name) ]
                    , span [] [ text ("(" ++ (res.rows |> List.length |> String.fromInt) ++ " rows)") ]
                    , span [] [ text (String.fromInt (Time.posixToMillis res.succeededAt - Time.posixToMillis res.startedAt) ++ " ms") ]
                    ]
                ]
                (div []
                    [ if res.showQuery then
                        div [ class "mt-1 relative" ]
                            [ button [ type_ "button", onClick (wrap ToggleQuery), class "absolute top-0 right-0 p-3 text-gray-500" ] [ Icon.solid Icon.X "w-3 h-3" ]
                            , model.query |> viewQuery False
                            ]

                      else
                        div [ class "mt-1 relative cursor-pointer", onClick (wrap ToggleQuery) ]
                            [ model.query |> viewQuery True ]
                    , viewTable wrap openModal (openRow model.source) openNotes defaultSchema source metadata res
                    ]
                )
                (div [ class "flex flex-shrink-0" ]
                    [ if List.length res.rows > 10 then
                        input
                            [ type_ "search"
                            , name (htmlId ++ "-search")
                            , placeholder "Search in results"
                            , value res.search
                            , onInput (UpdateSearch >> wrap)
                            , class "mr-1 rounded-full border-0 px-2 py-0 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                            ]
                            []

                      else
                        text ""
                    , Dropdown.dropdown { id = dropdownId, direction = BottomLeft, isOpen = openedDropdown == dropdownId }
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
                        (\_ ->
                            div []
                                ([ { label = Bool.cond res.fullScreen "Exit full screen" "Full screen", content = ContextMenu.Simple { action = ToggleFullScreen |> wrap } }
                                 , { label = Bool.cond res.documentMode "Table mode" "Document mode", content = ContextMenu.Simple { action = ToggleDocumentMode |> wrap } }
                                 , { label = "Refresh data", content = ContextMenu.Simple { action = Refresh |> wrap } }
                                 , { label = "Export data"
                                   , content =
                                        ContextMenu.SubMenu
                                            [ { label = "CSV", action = ExportData "csv" |> wrap }
                                            , { label = "JSON", action = ExportData "json" |> wrap }
                                            ]
                                            ContextMenu.BottomLeft
                                   }
                                 , { label = "Delete", content = ContextMenu.Simple { action = deleteQuery } }
                                 ]
                                    |> List.map ContextMenu.btnSubmenu
                                )
                        )
                    ]
                )


viewCard : Bool -> List (Html msg) -> Html msg -> Html msg -> Html msg
viewCard fullScreen cardTitle cardBody cardActions =
    div [ class "bg-white", classList [ ( "p-3 fixed inset-0 overflow-y-auto z-max", fullScreen ) ] ]
        [ div [ class "flex items-start space-x-3" ]
            [ div [ class "min-w-0 flex-1" ] cardTitle
            , div [ class "flex flex-shrink-0" ] [ cardActions ]
            ]
        , cardBody
        ]


viewQuery : Bool -> SqlQueryOrigin -> Html msg
viewQuery collapsed query =
    div [ css [ "block rounded bg-gray-50 border border-gray-200", Bool.cond collapsed "px-2 py-1 text-xs truncate" "px-3 py-2 text-sm whitespace-pre overflow-x-auto" ] ]
        [ text query.sql
        ]


viewActionButton : Icon -> String -> msg -> Html msg
viewActionButton icon name msg =
    button [ type_ "button", onClick msg, title name, class "flex items-center rounded-full text-gray-400 hover:text-gray-600" ]
        [ span [ class "sr-only" ] [ text name ], Icon.outline icon "w-4 h-4" ]


viewTable : (Msg -> msg) -> ((msg -> String -> Html msg) -> msg) -> (RowQuery -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> SchemaName -> Maybe Source -> Metadata -> SuccessState -> Html msg
viewTable wrap openModal openRow openNotes defaultSchema source metadata res =
    let
        items : List ( QueryResultRow, RowIndex )
        items =
            res.rows |> List.zipWithIndex |> filterValues res.search |> sortValues res.sortBy

        pagination : Pagination.Model
        pagination =
            if res.fullScreen then
                { currentPage = 1, pageSize = items |> List.length, totalItems = items |> List.length }

            else
                { currentPage = res.page, pageSize = 10, totalItems = items |> List.length }

        pageRows : List ( PageIndex, ( QueryResultRow, RowIndex ) )
        pageRows =
            Pagination.paginate items pagination

        ( columns, rows ) =
            if res.documentMode then
                "document" |> (\pathStr -> ( [ { path = ColumnPath.fromString pathStr, pathStr = pathStr, ref = Nothing, fk = Nothing } ], pageRows |> List.map (Tuple.mapSecond (Tuple.mapFirst (\r -> Dict.fromList [ ( pathStr, DbObject r ) ]))) ))

            else
                ( res.columns |> QueryResult.buildColumnTargets source, pageRows )
    in
    div [ class "mt-1" ]
        [ div [ class "flow-root" ]
            [ div [ class "overflow-x-auto" ]
                [ div [ class "inline-block min-w-full align-middle" ]
                    [ table [ class "table-auto min-w-full border-separate border-spacing-0" ]
                        -- sticky header: https://reacthustle.com/blog/how-to-create-react-table-sticky-headers-with-tailwindcss
                        [ thead []
                            [ tr [ class "bg-gray-100" ]
                                (th [ scope "col", onClick (UpdateSort Nothing |> wrap), class "px-1 sticky left-0 text-left text-sm font-semibold text-gray-900 border-b border-r border-gray-300 bg-gray-100 cursor-pointer" ] [ text "#" ]
                                    :: (columns |> List.map (\c -> viewTableHeader wrap openModal openNotes source metadata res.collapsed res.sortBy (items |> List.map Tuple.first) c))
                                )
                            ]
                        , tbody []
                            (rows
                                |> List.map
                                    (\( pi, ( r, ri ) ) ->
                                        let
                                            rest : Dict ColumnPathStr DbValue
                                            rest =
                                                r |> Dict.filter (\k _ -> columns |> List.memberBy .pathStr k |> not)
                                        in
                                        tr [ class "hover:bg-gray-100", classList [ ( "bg-gray-50", modBy 2 pi == 1 ) ] ]
                                            ([ td [ class ("px-1 sticky left-0 z-10 text-sm text-gray-900 border-r border-gray-300 hover:bg-gray-100 " ++ Bool.cond (modBy 2 pi == 1) "bg-gray-50" "bg-white") ] [ text (ri + 1 |> String.fromInt) ] ]
                                                ++ (columns |> List.map (\c -> viewTableValue openRow (ExpandRow ri |> wrap) defaultSchema res.documentMode (res.expanded |> Set.member ri) (res.collapsed |> Set.member c.pathStr) (r |> Dict.get c.pathStr) c))
                                                ++ (if rest |> Dict.isEmpty then
                                                        []

                                                    else
                                                        [ viewTableValue openRow (ExpandRow ri |> wrap) defaultSchema res.documentMode (res.expanded |> Set.member ri) (res.collapsed |> Set.member "rest") (rest |> DbObject |> Just) { path = Nel "rest" [], pathStr = "rest", ref = Nothing, fk = Nothing } ]
                                                   )
                                            )
                                    )
                            )
                        ]
                    ]
                ]
            ]
        , Pagination.view (\p -> ChangePage p |> wrap) pagination
        ]


viewTableHeader : (Msg -> msg) -> ((msg -> String -> Html msg) -> msg) -> (TableId -> Maybe ColumnPath -> msg) -> Maybe Source -> Metadata -> Set ColumnName -> Maybe String -> List QueryResultRow -> QueryResultColumnTarget -> Html msg
viewTableHeader wrap openModal openNotes source metadata collapsed sortBy rows column =
    let
        comment : Maybe Comment
        comment =
            column.ref |> Maybe.andThen (\ref -> source |> Maybe.andThen (Source.getColumn ref)) |> Maybe.andThen .comment

        notes : Maybe ( Notes, ColumnRef )
        notes =
            column.ref |> Maybe.andThen (\ref -> metadata |> Dict.get ref.table |> Maybe.andThen (.columns >> Dict.get (ref.column |> ColumnPath.toString)) |> Maybe.andThen (\m -> m.notes |> Maybe.map (\n -> ( n, ref ))))

        sort : Maybe ( String, Bool )
        sort =
            sortBy
                |> Maybe.map extractSort
                |> Maybe.filter (\( c, _ ) -> c == column.pathStr)
    in
    if collapsed |> Set.member column.pathStr then
        th [ scope "col", title (ColumnPath.show column.path), class "px-1 text-left text-sm font-semibold text-gray-900 border-b border-gray-300" ]
            [ button [ type_ "button", onClick (CollapseColumn column.pathStr |> wrap), class "ml-1 opacity-50" ] [ Icon.outline Icon.PlusCircle "w-3 h-3 inline" ]
            ]

    else
        th [ scope "col", class "px-1 text-left text-sm font-semibold text-gray-900 border-b border-gray-300 whitespace-nowrap group" ]
            [ text (ColumnPath.show column.path)
            , comment |> Maybe.mapOrElse (\c -> span [ title c.text, class "ml-1 opacity-50" ] [ Icon.outline Icons.comment "w-3 h-3 inline" ]) (text "")
            , notes |> Maybe.mapOrElse (\( n, ref ) -> button [ type_ "button", onClick (openNotes ref.table (Just ref.column)), title n, class "ml-1 opacity-50" ] [ Icon.outline Icons.notes "w-3 h-3 inline" ]) (text "")
            , button [ type_ "button", onClick (sort |> Maybe.mapOrElse (\( col, asc ) -> Bool.cond asc ("-" ++ col) col) column.pathStr |> Just |> UpdateSort |> wrap), title "Sort column", class "ml-1 opacity-50" ]
                [ sort
                    |> Maybe.map (\( _, asc ) -> Icon.solid (Bool.cond asc Icon.SortDescending Icon.SortAscending) "w-3 h-3 inline")
                    |> Maybe.withDefault (Icon.solid Icon.SortDescending "w-3 h-3 inline invisible group-hover:visible")
                ]
            , button [ type_ "button", onClick (CollapseColumn column.pathStr |> wrap), title "Collapse column", class "ml-1 opacity-50" ] [ Icon.outline Icon.MinusCircle "w-3 h-3 inline invisible group-hover:visible" ]
            , button [ type_ "button", onClick (openModal (DataExplorerStats.view column (rows |> List.filterMap (Dict.get column.pathStr)))), title "Column stats", class "ml-1 opacity-50" ] [ Icon.solid Icon.ChartPie "w-3 h-3 inline invisible group-hover:visible" ]
            ]


viewTableValue : (RowQuery -> msg) -> msg -> SchemaName -> Bool -> Bool -> Bool -> Maybe DbValue -> QueryResultColumnTarget -> Html msg
viewTableValue openRow expandRow defaultSchema documentMode expanded collapsed value column =
    td [ class "px-1 text-sm text-gray-500 whitespace-nowrap max-w-xs truncate" ]
        [ if collapsed then
            div [] []

          else
            DataExplorerValue.view openRow expandRow defaultSchema documentMode expanded value column
        ]


filterValues : String -> List ( QueryResultRow, RowIndex ) -> List ( QueryResultRow, RowIndex )
filterValues search items =
    if String.length search > 0 then
        let
            ( exactMatch, _ ) =
                items |> List.partition (Tuple.first >> Dict.any (\_ -> DbValue.toString >> String.contains search))

            --( fuzzyMatch, _ ) =
            --    noMatch |> List.partition (Tuple.first >> Dict.any (\_ -> DbValue.toString >> Simple.Fuzzy.match search))
        in
        --exactMatch ++ fuzzyMatch
        exactMatch

    else
        items


sortValues : Maybe String -> List ( QueryResultRow, RowIndex ) -> List ( QueryResultRow, RowIndex )
sortValues sort items =
    sort |> Maybe.mapOrElse (extractSort >> (\( col, dir ) -> items |> List.sortWith (\( a, _ ) ( b, _ ) -> compareMaybe DbValue.compare (a |> Dict.get col) (b |> Dict.get col) |> Order.dir dir))) items


extractSort : String -> ( ColumnPathStr, Bool )
extractSort sortBy =
    if sortBy |> String.startsWith "-" then
        ( sortBy |> String.stripLeft "-", False )

    else
        ( sortBy, True )



-- DOCUMENTATION


type alias SharedDocState x =
    { x | dataExplorerQueryDocState : DocState }


type alias DocState =
    { openedDropdown : HtmlId, success : Model, longLines : Model }


docInit : DocState
docInit =
    { openedDropdown = ""
    , success = docModel 1 docCityQuery docCitySuccess
    , longLines = docModel 2 docUsersQuery docUsersSuccess
    }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "DataExplorerQuery"
        |> Chapter.renderStatefulComponentList
            [ docComponentState "success" .success (\s m -> { s | success = m })
            , docComponentState "long lines & json" .longLines (\s m -> { s | longLines = m })
            , docComponent "failure" (\s -> view docWrap (docToggleDropdown s) docOpenModal docOpenRow docDelete docOpenNotes s.openedDropdown docDefaultSchema (Just docSource) docMetadata docHtmlId (docModel 3 docComplexQuery docStateFailure))
            , docComponent "running" (\s -> view docWrap (docToggleDropdown s) docOpenModal docOpenRow docDelete docOpenNotes s.openedDropdown docDefaultSchema (Just docSource) docMetadata docHtmlId (docModel 4 docComplexQuery docStateRunning))
            , docComponent "canceled" (\s -> view docWrap (docToggleDropdown s) docOpenModal docOpenRow docDelete docOpenNotes s.openedDropdown docDefaultSchema (Just docSource) docMetadata docHtmlId (docModel 5 docComplexQuery docStateCanceled))
            ]


docModel : Int -> SqlQuery -> State -> Model
docModel id query state =
    { id = id, source = docSource |> DbSourceInfo.fromSource |> Maybe.withDefault DbSourceInfo.zero, query = { sql = query, origin = "doc", db = DatabaseKind.Other }, state = state }


docComplexQuery : SqlQuery
docComplexQuery =
    """SELECT
    u.id,
    u.name,
    u.avatar,
    u.email,
    count(distinct to_char(e.created_at, 'yyyy-mm-dd')) as active_days,
    count(*) as nb_events,
    max(e.created_at) as last_activity
FROM events e JOIN users u on u.id = e.created_by
GROUP BY u.id
HAVING count(distinct to_char(e.created_at, 'yyyy-mm-dd')) >= 5 AND max(e.created_at) < NOW() - INTERVAL '30 days'
ORDER BY last_activity DESC;"""


docDefaultSchema : SchemaName
docDefaultSchema =
    "public"


docHtmlId : HtmlId
docHtmlId =
    "data-explorer-query"


docStateRunning : State
docStateRunning =
    StateRunning


docStateCanceled : State
docStateCanceled =
    StateCanceled


docStateFailure : State
docStateFailure =
    { error = "Error: relation \"events\" does not exist\nError Code: 42P01", startedAt = Time.zero, failedAt = Time.zero } |> StateFailure


docCityQuery : SqlQuery
docCityQuery =
    "SELECT * FROM city;"


docCitySuccess : State
docCitySuccess =
    { columns = [ "id", "name", "country_code", "district", "population" ] |> List.map (docColumn "public" "city")
    , rows =
        [ docCityColumnValues 1 "Kabul" "AFG" "Kabol" 1780000
        , docCityColumnValues 2 "Qandahar" "AFG" "Qandahar" 237500
        , docCityColumnValues 3 "Herat" "AFG" "Herat" 186800
        , docCityColumnValues 4 "Mazar-e-Sharif" "AFG" "Balkh" 127800
        , docCityColumnValues 5 "Amsterdam" "NLD" "Noord-Holland" 731200
        , docCityColumnValues 6 "Rotterdam" "NLD" "Zuid-Holland" 593321
        , docCityColumnValues 7 "Haag" "NLD" "Zuid-Holland" 440900
        , docCityColumnValues 8 "Utrecht" "NLD" "Utrecht" 234323
        , docCityColumnValues 9 "Eindhoven" "NLD" "Noord-Brabant" 201843
        , docCityColumnValues 10 "Tilburg" "NLD" "Noord-Brabant" 193238
        , docCityColumnValues 11 "Groningen" "NLD" "Groningen" 172701
        , docCityColumnValues 12 "Breda" "NLD" "Noord-Brabant" 160398
        , docCityColumnValues 13 "Apeldoorn" "NLD" "Gelderland" 153491
        , docCityColumnValues 14 "Nijmegen" "NLD" "Gelderland" 152463
        , docCityColumnValues 15 "Enschede" "NLD" "Overijssel" 149544
        , docCityColumnValues 16 "Haarlem" "NLD" "Noord-Holland" 148772
        , docCityColumnValues 17 "Almere" "NLD" "Flevoland" 142465
        , docCityColumnValues 18 "Arnhem" "NLD" "Gelderland" 138020
        , docCityColumnValues 19 "Zaanstad" "NLD" "Noord-Holland" 135621
        , docCityColumnValues 20 "´s-Hertogenbosch" "NLD" "Noord-Brabant" 129170
        , docCityColumnValues 21 "Amersfoort" "NLD" "Utrecht" 126270
        , docCityColumnValues 22 "Maastricht" "NLD" "Limburg" 122087
        , docCityColumnValues 23 "Dordrecht" "NLD" "Zuid-Holland" 119811
        , docCityColumnValues 24 "Leiden" "NLD" "Zuid-Holland" 117196
        , docCityColumnValues 25 "Haarlemmermeer" "NLD" "Noord-Holland" 110722
        , docCityColumnValues 26 "Zoetermeer" "NLD" "Zuid-Holland" 110214
        , docCityColumnValues 27 "Emmen" "NLD" "Drenthe" 105853
        , docCityColumnValues 28 "Zwolle" "NLD" "Overijssel" 105819
        , docCityColumnValues 29 "Ede" "NLD" "Gelderland" 101574
        , docCityColumnValues 30 "Delft" "NLD" "Zuid-Holland" 95268
        , docCityColumnValues 31 "Heerlen" "NLD" "Limburg" 95052
        , docCityColumnValues 32 "Alkmaar" "NLD" "Noord-Holland" 92713
        , docCityColumnValues 33 "Willemstad" "ANT" "Curaçao" 2345
        , docCityColumnValues 34 "Tirana" "ALB" "Tirana" 270000
        , docCityColumnValues 35 "Alger" "DZA" "Alger" 2168000
        , docCityColumnValues 36 "Oran" "DZA" "Oran" 609823
        , docCityColumnValues 37 "Constantine" "DZA" "Constantine" 443727
        , docCityColumnValues 38 "Annaba" "DZA" "Annaba" 222518
        , docCityColumnValues 39 "Batna" "DZA" "Batna" 183377
        , docCityColumnValues 40 "Sétif" "DZA" "Sétif" 179055
        , docCityColumnValues 41 "Sidi Bel Abbès" "DZA" "Sidi Bel Abbès" 153106
        , docCityColumnValues 42 "Skikda" "DZA" "Skikda" 128747
        , docCityColumnValues 43 "Biskra" "DZA" "Biskra" 128281
        , docCityColumnValues 44 "Blida (el-Boulaida)" "DZA" "Blida" 127284
        , docCityColumnValues 45 "Béjaïa" "DZA" "Béjaïa" 117162
        , docCityColumnValues 46 "Mostaganem" "DZA" "Mostaganem" 115212
        , docCityColumnValues 47 "Tébessa" "DZA" "Tébessa" 112007
        ]
    }
        |> initSuccess Time.zero Time.zero


docUsersQuery : String
docUsersQuery =
    "SELECT * FROM users;"


docUsersSuccess : State
docUsersSuccess =
    { columns = [ "id", "slug", "name", "email", "provider", "provider_uid", "avatar", "github_username", "twitter_username", "is_admin", "hashed_password", "last_signin", "created_at", "updated_at", "confirmed_at", "deleted_at", "data", "onboarding", "provider_data", "tags" ] |> List.map (docColumn "public" "users")
    , rows =
        [ docUsersColumnValues "4a3ea674-cff6-44de-b217-3befbe907a95" "admin" "Azimutt Admin" "admin@azimutt.app" Nothing Nothing "https://robohash.org/set_set3/bgset_bg2/VghiKo" (Just "azimuttapp") (Just "azimuttapp") True (Just "$2b$12$5TukDUCUtXm1zu0TECv34eg8SHueHqXUGQ9pvDZA55LUnH30ZEpUa") "2023-04-26T18:28:27.343Z" "2023-04-26T18:28:27.355Z" "2023-04-26T18:28:27.355Z" "2023-04-26T18:28:27.343Z" Nothing (Dict.fromList [ ( "attributed_from", DbString "root" ), ( "attributed_to", DbNull ) ]) Dict.empty [ DbString "admin" ]
        , docUsersColumnValues "11bd9544-d56a-43d7-9065-6f1f25addf8a" "loicknuchel" "Loïc Knuchel" "loicknuchel@gmail.com" (Just "github") (Just "653009") "https://avatars.githubusercontent.com/u/653009?v=4" (Just "loicknuchel") (Just "loicknuchel") True Nothing "2023-04-27T15:55:11.582Z" "2023-04-27T15:55:11.612Z" "2023-07-19T18:57:53.438Z" "2023-04-27T15:55:11.582Z" Nothing (Dict.fromList [ ( "attributed_from", DbNull ), ( "attributed_to", DbNull ) ]) Dict.empty [ DbNull, DbString "user" ]
        ]
    }
        |> initSuccess Time.zero Time.zero


docProjectsQuery : String
docProjectsQuery =
    "SELECT * FROM projects;"


docProjectsSuccess : State
docProjectsSuccess =
    { columns = [ "id", "organization_id", "slug", "name", "created_by", "created_at" ] |> List.map (docColumn "public" "projects")
    , rows =
        [ docProjectsColumnValues "9505930b-9d15-4c40-98f2-c730fcbef2dd" "104af15e-54ae-4c12-b293-8846be293203" "basic" "Basic" "4a3ea674-cff6-44de-b217-3befbe907a95" "2023-04-26 20:28:28.436054"
        , docProjectsColumnValues "e2b89bfc-2b4d-4c31-a92c-9ca6584c348c" "2d803b04-90d7-4e05-940f-5e887470b595" "gospeak-sql" "gospeak.sql" "11bd9544-d56a-43d7-9065-6f1f25addf8a" "2023-04-27 18:05:28.643297"
        ]
    }
        |> initSuccess Time.zero Time.zero


docColumn : SchemaName -> TableName -> ColumnPathStr -> QueryResultColumn
docColumn schema table pathStr =
    { path = ColumnPath.fromString pathStr, pathStr = pathStr, ref = Just { table = ( schema, table ), column = ColumnPath.fromString pathStr } }


docCityColumnValues : Int -> String -> String -> String -> Int -> QueryResultRow
docCityColumnValues id name country_code district population =
    Dict.fromList [ ( "id", DbInt id ), ( "name", DbString name ), ( "country_code", DbString country_code ), ( "district", DbString district ), ( "population", DbInt population ) ]


docProjectsColumnValues : String -> String -> String -> String -> String -> String -> QueryResultRow
docProjectsColumnValues id organization_id slug name created_by created_at =
    [ ( "id", id ), ( "organization_id", organization_id ), ( "slug", slug ), ( "name", name ), ( "created_by", created_by ), ( "created_at", created_at ) ] |> List.map (\( key, value ) -> ( key, DbString value )) |> Dict.fromList


docUsersColumnValues : String -> String -> String -> String -> Maybe String -> Maybe String -> String -> Maybe String -> Maybe String -> Bool -> Maybe String -> String -> String -> String -> String -> Maybe String -> Dict String DbValue -> Dict String DbValue -> List DbValue -> QueryResultRow
docUsersColumnValues id slug name email provider provider_uid avatar github_username twitter_username is_admin hashed_password last_signin created_at updated_at confirmed_at deleted_at data provider_data tags =
    let
        str : List ( String, DbValue )
        str =
            [ ( "id", id ), ( "slug", slug ), ( "name", name ), ( "email", email ), ( "avatar", avatar ), ( "last_signin", last_signin ), ( "created_at", created_at ), ( "updated_at", updated_at ), ( "confirmed_at", confirmed_at ) ] |> List.map (\( key, value ) -> ( key, DbString value ))

        strOpt : List ( String, DbValue )
        strOpt =
            [ ( "provider", provider ), ( "provider_uid", provider_uid ), ( "github_username", github_username ), ( "twitter_username", twitter_username ), ( "hashed_password", hashed_password ), ( "deleted_at", deleted_at ) ] |> List.map (\( key, value ) -> ( key, value |> Maybe.mapOrElse (\v -> DbString v) DbNull ))

        bool : List ( String, DbValue )
        bool =
            [ ( "is_admin", is_admin ) ] |> List.map (\( key, value ) -> ( key, DbBool value ))

        arr : List ( String, DbValue )
        arr =
            [ ( "tags", tags ) ] |> List.map (\( key, value ) -> ( key, DbArray value ))

        obj : List ( String, DbValue )
        obj =
            [ ( "data", data ), ( "provider_data", provider_data ) ] |> List.map (\( key, value ) -> ( key, DbObject value ))
    in
    Dict.fromList (str ++ strOpt ++ bool ++ arr ++ obj)


docSource : Source
docSource =
    { id = SourceId.zero
    , name = "azimutt_dev"
    , kind = DatabaseConnection "postgresql://postgres:postgres@localhost:5432/azimutt_dev"
    , content = Array.empty
    , tables =
        [ docTable "public" "users" [ ( "id", "uuid", False ), ( "slug", "varchar", False ), ( "name", "varchar", False ), ( "email", "varchar", False ), ( "provider", "varchar", True ), ( "provider_uid", "varchar", True ), ( "avatar", "varchar", False ), ( "github_username", "varchar", True ), ( "twitter_username", "varchar", True ), ( "is_admin", "boolean", False ), ( "hashed_password", "varchar", True ), ( "last_signin", "timestamp", False ), ( "created_at", "timestamp", False ), ( "updated_at", "timestamp", False ), ( "confirmed_at", "timestamp", True ), ( "deleted_at", "timestamp", True ), ( "data", "json", False ), ( "onboarding", "json", False ), ( "provider_data", "json", True ), ( "tags", "varchar[]", False ) ]
        , docTable "public" "organizations" [ ( "id", "uuid", False ), ( "name", "varchar", False ), ( "data", "json", True ), ( "created_by", "uuid", True ), ( "created_at", "timestamp", False ) ]
        , docTable "public" "projects" [ ( "id", "uuid", False ), ( "organization_id", "uuid", False ), ( "slug", "varchar", False ), ( "name", "varchar", False ), ( "created_by", "uuid", True ), ( "created_at", "timestamp", False ) ]
        , docTable "public" "events" [ ( "id", "uuid", False ), ( "name", "varchar", False ), ( "data", "json", True ), ( "details", "json", True ), ( "created_by", "uuid", True ), ( "created_at", "timestamp", False ), ( "organization_id", "uuid", True ), ( "project_id", "uuid", True ) ]
        , docTable "public" "city" [ ( "id", "int", False ), ( "name", "varchar", False ), ( "country_code", "varchar", False ), ( "district", "varchar", False ), ( "population", "int", False ) ]
        ]
            |> Dict.fromListMap .id
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


docTable : SchemaName -> TableName -> List ( ColumnName, ColumnType, Bool ) -> Table
docTable schema name columns =
    { id = ( schema, name )
    , schema = schema
    , name = name
    , view = False
    , columns = columns |> List.indexedMap (\i ( col, kind, nullable ) -> { index = i, name = col, kind = kind, nullable = nullable, default = Nothing, comment = Nothing, values = Nothing, columns = Nothing }) |> Dict.fromListMap .name
    , primaryKey = Just { name = Just (name ++ "_pk"), columns = Nel (Nel "id" []) [] }
    , uniques = []
    , indexes = []
    , checks = []
    , comment = Nothing
    }


docRelation : ( SchemaName, TableName, ColumnName ) -> ( SchemaName, TableName, ColumnName ) -> Relation
docRelation ( fromSchema, fromTable, fromColumn ) ( toSchema, toTable, toColumn ) =
    Relation.new (fromTable ++ "." ++ fromColumn ++ "->" ++ toTable ++ "." ++ toColumn) { table = ( fromSchema, fromTable ), column = Nel fromColumn [] } { table = ( toSchema, toTable ), column = Nel toColumn [] }


docMetadata : Metadata
docMetadata =
    Dict.empty



-- DOC HELPERS


docComponent : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
docComponent name render =
    ( name, \{ dataExplorerQueryDocState } -> render dataExplorerQueryDocState )


docComponentState : String -> (DocState -> Model) -> (DocState -> Model -> DocState) -> ( String, SharedDocState x -> Html (ElmBook.Msg (SharedDocState x)) )
docComponentState name get set =
    ( name, \{ dataExplorerQueryDocState } -> dataExplorerQueryDocState |> (\s -> get s |> (\m -> view (docUpdate s get set) (docToggleDropdown s) docOpenModal docOpenRow docDelete docOpenNotes s.openedDropdown docDefaultSchema (Just docSource) docMetadata (docHtmlId ++ "-" ++ String.fromInt m.id) m)) )


docUpdate : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate s get set m =
    s |> get |> update docShowToast ProjectInfo.zero m |> Tuple.first |> set s |> docSetState


docToggleDropdown : DocState -> HtmlId -> ElmBook.Msg (SharedDocState x)
docToggleDropdown s id =
    if s.openedDropdown == id then
        docSetState { s | openedDropdown = "" }

    else
        docSetState { s | openedDropdown = id }


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | dataExplorerQueryDocState = state })


docWrap : Msg -> ElmBook.Msg state
docWrap =
    \_ -> logAction "wrap"


docShowToast : Toasts.Msg -> ElmBook.Msg state
docShowToast _ =
    logAction "showToast"


docOpenModal : (msg -> String -> Html msg) -> ElmBook.Msg (SharedDocState x)
docOpenModal _ =
    logAction "openModal"


docOpenRow : DbSourceInfo -> RowQuery -> ElmBook.Msg state
docOpenRow =
    \_ _ -> logAction "openRow"


docDelete : ElmBook.Msg state
docDelete =
    logAction "delete"


docOpenNotes : TableId -> Maybe ColumnPath -> ElmBook.Msg state
docOpenNotes _ _ =
    logAction "openNotes"
