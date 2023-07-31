module Components.Slices.DataExplorerQuery exposing (CanceledState, DocState, FailureState, Model, Msg(..), QueryId, QueryState(..), RowIndex, SharedDocState, SuccessState, doc, docCityQuery, docCitySuccess, docInit, docProjectsQuery, docProjectsSuccess, docRelation, docSource, docTable, docUsersQuery, docUsersSuccess, init, update, view)

import Array
import Components.Atoms.Icon as Icon exposing (Icon)
import Components.Molecules.ContextMenu as ContextMenu exposing (Direction(..))
import Components.Molecules.Dropdown as Dropdown
import Components.Molecules.Pagination as Pagination
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, p, pre, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, classList, id, scope, title, type_)
import Html.Events exposing (onClick)
import Libs.Dict as Dict
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel exposing (Nel)
import Libs.Tailwind exposing (TwClass, focus)
import Libs.Task as T
import Libs.Time as Time
import Models.DatabaseQueryResults exposing (DatabaseQueryResultsColumn, DatabaseQueryResultsRow)
import Models.JsValue as JsValue exposing (JsValue)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import Models.SourceInfo exposing (SourceInfo)
import Services.Lenses exposing (mapExecutions, mapHead, mapState)
import Services.QueryBuilder as QueryBuilder
import Time


type alias QueryId =
    Int


type alias RowIndex =
    Int


type alias Model =
    { id : QueryId
    , source : SourceInfo
    , query : String
    , executions : Nel { startedAt : Time.Posix, state : QueryState }
    }


type QueryState
    = StateRunning
    | StateCanceled CanceledState
    | StateFailure FailureState
    | StateSuccess SuccessState


type alias CanceledState =
    { canceledAt : Time.Posix }


type alias FailureState =
    { error : String, failedAt : Time.Posix }


type alias SuccessState =
    { columns : List DatabaseQueryResultsColumn
    , rows : List DatabaseQueryResultsRow
    , durationMs : Int
    , succeededAt : Time.Posix
    , page : Int
    , expanded : Dict RowIndex Bool
    , documentMode : Bool
    , showQuery : Bool
    , search : String
    , sortBy : Maybe String
    , fullScreen : Bool
    }


type Msg
    = FullScreen
    | Refresh -- run again the query
    | Export -- export results in csv or json (or copy in clipboard)
    | Cancel -- stop a query in a running state (only UI?)
    | OpenRow ColumnRef -- open a single row in sidebar
      -- used message ^^
    | ChangePage Int
    | ExpandRow RowIndex
    | ToggleQuery
    | Noop



-- INIT


init : QueryId -> SourceInfo -> String -> Time.Posix -> Model
init id source query startedAt =
    { id = id, source = source, query = query, executions = Nel { startedAt = startedAt, state = StateRunning } [] }



-- UPDATE


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update wrap msg model =
    case msg of
        ChangePage p ->
            ( model |> mapExecutions (mapHead (mapState (mapSuccess (\s -> { s | page = p })))), Cmd.none )

        ExpandRow i ->
            ( model |> mapExecutions (mapHead (mapState (mapSuccess (\s -> { s | expanded = s.expanded |> Dict.update i (Maybe.mapOrElse not True >> Just) })))), Cmd.none )

        ToggleQuery ->
            ( model |> mapExecutions (mapHead (mapState (mapSuccess (\s -> { s | showQuery = not s.showQuery })))), Cmd.none )

        Noop ->
            ( model, Cmd.none )

        _ ->
            -- FIXME to remove
            ( model, Noop |> wrap |> T.send )


mapSuccess : (SuccessState -> SuccessState) -> QueryState -> QueryState
mapSuccess f state =
    case state of
        StateSuccess s ->
            StateSuccess (f s)

        _ ->
            state



-- VIEW


view : (Msg -> msg) -> (HtmlId -> msg) -> (SourceInfo -> QueryBuilder.RowQuery -> msg) -> msg -> Time.Posix -> HtmlId -> SchemaName -> List Source -> HtmlId -> Model -> Html msg
view wrap openDropdown openRow deleteQuery now openedDropdown defaultSchema sources htmlId model =
    case model.executions.head.state of
        StateRunning ->
            viewCard
                [ p [ class "text-sm font-semibold text-gray-900" ] [ text ("#" ++ String.fromInt model.id ++ " " ++ model.source.name) ]
                , p [ class "mt-1 text-sm text-gray-500 space-x-2" ]
                    [ span [ class "font-bold text-amber-500" ] [ text "Running..." ]
                    , span [ class "relative inline-flex h-2 w-2" ]
                        [ span [ class "animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75" ] []
                        , span [ class "relative inline-flex rounded-full h-2 w-2 bg-amber-500" ] []
                        ]
                    , span [] [ text (String.fromInt (Time.posixToMillis now - Time.posixToMillis model.executions.head.startedAt) ++ " ms") ]
                    ]
                ]
                (div [ class "mt-3" ] [ viewQuery "px-6 py-4 text-sm" model.query ])
                (div [ class "relative flex space-x-1 text-left" ] [ viewActionButton "Cancel execution" Icon.XCircle ])

        StateCanceled res ->
            viewCard
                [ p [ class "text-sm font-semibold text-gray-900" ] [ text ("#" ++ String.fromInt model.id ++ " " ++ model.source.name) ]
                , p [ class "mt-1 text-sm text-gray-500 space-x-2" ]
                    [ span [ class "font-bold" ] [ text "Canceled!" ]
                    , span [] [ text (String.fromInt (Time.posixToMillis res.canceledAt - Time.posixToMillis model.executions.head.startedAt) ++ " ms") ]
                    ]
                ]
                (div [ class "mt-3" ] [ viewQuery "px-6 py-4 text-sm" model.query ])
                (div [ class "relative flex space-x-1 text-left" ] [ viewActionButton "Delete" Icon.Trash ])

        StateFailure res ->
            viewCard
                [ p [ class "text-sm font-semibold text-gray-900" ] [ text ("#" ++ String.fromInt model.id ++ " " ++ model.source.name) ]
                , p [ class "mt-1 text-sm text-gray-500 space-x-1" ]
                    [ span [ class "font-bold text-red-500" ] [ text "Failed" ]
                    , span [] [ text (String.fromInt (Time.posixToMillis res.failedAt - Time.posixToMillis model.executions.head.startedAt) ++ " ms") ]
                    ]
                ]
                (div []
                    [ p [ class "mt-3 text-sm font-semibold text-gray-900" ] [ text "Error" ]
                    , pre [ class "px-6 py-4 block text-sm whitespace-pre overflow-x-auto rounded bg-red-50 border border-red-200" ] [ text res.error ]
                    , p [ class "mt-3 text-sm font-semibold text-gray-900" ] [ text "SQL" ]
                    , viewQuery "px-6 py-4 text-sm" model.query
                    ]
                )
                (div [ class "relative flex space-x-1 text-left" ]
                    [ viewActionButton "Run again execution" Icon.Refresh
                    , viewActionButton "Delete" Icon.Trash
                    ]
                )

        StateSuccess res ->
            let
                dropdownId : HtmlId
                dropdownId =
                    htmlId ++ "-settings"
            in
            viewCard
                [ p [ class "text-sm text-gray-500 space-x-1" ]
                    [ span [ class "font-semibold text-gray-900" ] [ text ("#" ++ String.fromInt model.id ++ " " ++ model.source.name) ]
                    , span [] [ text ("(" ++ (res.rows |> List.length |> String.fromInt) ++ " rows)") ]
                    , span [] [ text (String.fromInt (Time.posixToMillis res.succeededAt - Time.posixToMillis model.executions.head.startedAt) ++ " ms") ]
                    ]
                ]
                (div []
                    [ if res.showQuery then
                        div [ class "relative mt-3" ]
                            [ button [ type_ "button", onClick (wrap ToggleQuery), class "absolute top-0 right-0 p-3 text-gray-500" ] [ Icon.solid Icon.X "w-3 h-3" ]
                            , viewQuery "px-6 py-4 text-sm" model.query
                            ]

                      else
                        div [ class "relative mt-3", onClick (wrap ToggleQuery) ]
                            [ viewQuery "px-2 py-1 text-xs cursor-pointer" (model.query |> String.split "\n" |> List.head |> Maybe.withDefault "") ]
                    , div [ class "mt-3" ] [ viewSuccess wrap (openRow model.source) defaultSchema (sources |> List.find (\s -> s.id == model.source.id)) res ]
                    ]
                )
                (Dropdown.dropdown { id = dropdownId, direction = BottomLeft, isOpen = openedDropdown == dropdownId }
                    (\m ->
                        button
                            [ type_ "button"
                            , id m.id
                            , onClick (openDropdown m.id)
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
                            ([ { label = "Explore in full screen", content = ContextMenu.Simple { action = wrap FullScreen } }
                             , { label = "Refresh data", content = ContextMenu.Simple { action = wrap Refresh } }
                             , { label = "Export data"
                               , content =
                                    ContextMenu.SubMenu
                                        [ { label = "CSV", action = wrap Refresh }
                                        , { label = "JSON", action = wrap Refresh }
                                        ]
                                        ContextMenu.BottomLeft
                               }
                             , { label = "Delete", content = ContextMenu.Simple { action = deleteQuery } }
                             ]
                                |> List.map ContextMenu.btnSubmenu
                            )
                    )
                )


viewCard : List (Html msg) -> Html msg -> Html msg -> Html msg
viewCard cardTitle cardBody cardActions =
    div [ class "bg-white" ]
        [ div [ class "flex items-start space-x-3" ]
            [ div [ class "min-w-0 flex-1" ] cardTitle
            , div [ class "flex flex-shrink-0" ] [ cardActions ]
            ]
        , cardBody
        ]


viewQuery : TwClass -> String -> Html msg
viewQuery classes query =
    pre [ css [ "block whitespace-pre overflow-x-auto rounded bg-gray-50 border border-gray-200", classes ] ] [ text query ]


viewActionButton : String -> Icon -> Html msg
viewActionButton name icon =
    button [ type_ "button", title name, class "flex items-center rounded-full text-gray-400 hover:text-gray-600" ]
        [ span [ class "sr-only" ] [ text name ], Icon.outline icon "w-4 h-4" ]


viewSuccess : (Msg -> msg) -> (QueryBuilder.RowQuery -> msg) -> SchemaName -> Maybe Source -> SuccessState -> Html msg
viewSuccess wrap openRow defaultSchema source res =
    let
        pagination : Pagination.Model
        pagination =
            { currentPage = res.page, pageSize = 10, totalItems = res.rows |> List.length }

        pageRows : List ( RowIndex, DatabaseQueryResultsRow )
        pageRows =
            Pagination.paginate res.rows pagination
    in
    div []
        [ viewTable wrap openRow defaultSchema source res.columns pageRows res.expanded
        , Pagination.view (\p -> ChangePage p |> wrap) pagination
        ]


viewTable : (Msg -> msg) -> (QueryBuilder.RowQuery -> msg) -> SchemaName -> Maybe Source -> List DatabaseQueryResultsColumn -> List ( RowIndex, DatabaseQueryResultsRow ) -> Dict RowIndex Bool -> Html msg
viewTable wrap openRow defaultSchema source columns rows expanded =
    -- TODO sort columns
    -- TODO document mode
    -- TODO open row sidebar
    let
        tables : Dict TableId Table
        tables =
            source |> Maybe.mapOrElse .tables Dict.empty

        relations : Dict TableId (List Relation)
        relations =
            source |> Maybe.mapOrElse (.relations >> List.groupBy (.src >> .table)) Dict.empty

        columns2 : List { name : String, open : Maybe { ref : ColumnRef, kind : ColumnType } }
        columns2 =
            columns |> List.map (\c -> { name = c.name, open = c.ref |> Maybe.andThen (targetColumn tables relations) })
    in
    div [ class "flow-root" ]
        [ div [ class "overflow-x-auto" ]
            [ div [ class "inline-block min-w-full align-middle" ]
                [ table [ class "min-w-full divide-y divide-gray-300" ]
                    [ thead []
                        [ tr [ class "bg-gray-100" ]
                            (th [ scope "col", class "px-1 text-left text-sm font-semibold text-gray-900" ] [ text "#" ]
                                :: (columns2 |> List.map (\c -> th [ scope "col", class "px-1 text-left text-sm font-semibold text-gray-900" ] [ text c.name ]))
                            )
                        ]
                    , tbody []
                        (rows
                            |> List.map
                                (\( i, r ) ->
                                    tr [ class "hover:bg-gray-100", classList [ ( "bg-gray-50", modBy 2 i == 1 ) ] ]
                                        (td [ class "px-1 text-sm text-gray-900" ] [ text (i |> String.fromInt) ]
                                            :: (columns2 |> List.map (viewTableValue wrap openRow defaultSchema i r expanded))
                                        )
                                )
                        )
                    ]
                ]
            ]
        ]


targetColumn : Dict TableId Table -> Dict TableId (List Relation) -> ColumnRef -> Maybe { ref : ColumnRef, kind : ColumnType }
targetColumn tables relations ref =
    let
        target : Maybe ColumnRef
        target =
            if tables |> Dict.get ref.table |> Maybe.andThen .primaryKey |> Maybe.any (\pk -> pk.columns == Nel ref.column []) then
                Just ref

            else
                relations |> Dict.getOrElse ref.table [] |> List.find (\r -> r.src == ref) |> Maybe.map .ref
    in
    target |> Maybe.andThen (\r -> tables |> Dict.get r.table |> Maybe.andThen (\t -> t |> Table.getColumn r.column) |> Maybe.map (\c -> { ref = r, kind = c.kind }))


viewTableValue : (Msg -> msg) -> (QueryBuilder.RowQuery -> msg) -> SchemaName -> RowIndex -> DatabaseQueryResultsRow -> Dict RowIndex Bool -> { name : String, open : Maybe { ref : ColumnRef, kind : ColumnType } } -> Html msg
viewTableValue wrap openRow defaultSchema i row expanded column =
    let
        value : Maybe JsValue
        value =
            row |> Dict.get column.name

        classes : TwClass
        classes =
            "px-1 text-sm text-gray-500 whitespace-nowrap max-w-xs truncate"
    in
    if value |> Maybe.any (\v -> JsValue.isArray v || JsValue.isObject v) then
        td [ onClick (ExpandRow i |> wrap), class (classes ++ " cursor-pointer") ]
            [ if expanded |> Dict.getOrElse i False then
                JsValue.viewRaw value

              else
                JsValue.view value
            ]

    else
        Maybe.map2
            (\o v ->
                td [ class classes ]
                    [ JsValue.view value
                    , button
                        [ type_ "button"
                        , onClick (openRow { table = o.ref.table, primaryKey = Nel { column = o.ref.column, kind = o.kind, value = JsValue.toString v } [] })
                        , title ("Open " ++ TableId.show defaultSchema o.ref.table ++ " with " ++ ColumnPath.show o.ref.column ++ "=" ++ JsValue.toString v)
                        ]
                        [ Icon.solid Icon.ExternalLink "ml-1 w-4 h-4 inline" ]
                    ]
            )
            column.open
            value
            |> Maybe.withDefault (td [ class classes ] [ JsValue.view value ])



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
            , docComponent "failure" (\s -> view docWrap docDropdown docOpenRow docDelete Time.zero s.openedDropdown docDefaultSchema docSources docHtmlId (docModel 3 docComplexQuery docStateFailure))
            , docComponent "running" (\s -> view docWrap docDropdown docOpenRow docDelete Time.zero s.openedDropdown docDefaultSchema docSources docHtmlId (docModel 4 docComplexQuery docStateRunning))
            , docComponent "canceled" (\s -> view docWrap docDropdown docOpenRow docDelete Time.zero s.openedDropdown docDefaultSchema docSources docHtmlId (docModel 5 docComplexQuery docStateCanceled))
            ]


docModel : Int -> String -> QueryState -> Model
docModel id query state =
    { id = id, source = Source.toInfo docSource, query = query, executions = Nel { startedAt = Time.zero, state = state } [] }


docComplexQuery : String
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


docSources : List Source
docSources =
    [ docSource ]


docHtmlId : HtmlId
docHtmlId =
    "data-explorer-query"


docStateRunning : QueryState
docStateRunning =
    StateRunning


docStateCanceled : QueryState
docStateCanceled =
    { canceledAt = Time.zero } |> StateCanceled


docStateFailure : QueryState
docStateFailure =
    { error = "Error: relation \"events\" does not exist\nError Code: 42P01", failedAt = Time.zero } |> StateFailure


docCityQuery : String
docCityQuery =
    "SELECT * FROM city;"


docCitySuccess : QueryState
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
        ]
    , durationMs = 934
    , succeededAt = Time.zero
    , page = 1
    , expanded = Dict.empty
    , showQuery = False
    , documentMode = False
    , search = ""
    , sortBy = Nothing
    , fullScreen = False
    }
        |> StateSuccess


docUsersQuery : String
docUsersQuery =
    "SELECT * FROM users;"


docUsersSuccess : QueryState
docUsersSuccess =
    { columns = [ "id", "slug", "name", "email", "provider", "provider_uid", "avatar", "github_username", "twitter_username", "is_admin", "hashed_password", "last_signin", "created_at", "updated_at", "confirmed_at", "deleted_at", "data", "onboarding", "provider_data", "tags" ] |> List.map (docColumn "public" "users")
    , rows =
        [ docUsersColumnValues "4a3ea674-cff6-44de-b217-3befbe907a95" "admin" "Azimutt Admin" "admin@azimutt.app" Nothing Nothing "https://robohash.org/set_set3/bgset_bg2/VghiKo" (Just "azimuttapp") (Just "azimuttapp") True (Just "$2b$12$5TukDUCUtXm1zu0TECv34eg8SHueHqXUGQ9pvDZA55LUnH30ZEpUa") "2023-04-26T18:28:27.343Z" "2023-04-26T18:28:27.355Z" "2023-04-26T18:28:27.355Z" "2023-04-26T18:28:27.343Z" Nothing (Dict.fromList [ ( "attributed_from", JsValue.String "root" ), ( "attributed_to", JsValue.Null ) ]) Dict.empty [ JsValue.String "admin" ]
        , docUsersColumnValues "11bd9544-d56a-43d7-9065-6f1f25addf8a" "loicknuchel" "Loïc Knuchel" "loicknuchel@gmail.com" (Just "github") (Just "653009") "https://avatars.githubusercontent.com/u/653009?v=4" (Just "loicknuchel") (Just "loicknuchel") True Nothing "2023-04-27T15:55:11.582Z" "2023-04-27T15:55:11.612Z" "2023-07-19T18:57:53.438Z" "2023-04-27T15:55:11.582Z" Nothing (Dict.fromList [ ( "attributed_from", JsValue.Null ), ( "attributed_to", JsValue.Null ) ]) Dict.empty [ JsValue.Null, JsValue.String "user" ]
        ]
    , durationMs = 934
    , succeededAt = Time.zero
    , page = 1
    , expanded = Dict.empty
    , showQuery = False
    , documentMode = False
    , search = ""
    , sortBy = Nothing
    , fullScreen = False
    }
        |> StateSuccess


docProjectsQuery : String
docProjectsQuery =
    "SELECT * FROM projects;"


docProjectsSuccess : QueryState
docProjectsSuccess =
    { columns = [ "id", "organization_id", "slug", "name", "created_by", "created_at" ] |> List.map (docColumn "public" "projects")
    , rows =
        [ docProjectsColumnValues "9505930b-9d15-4c40-98f2-c730fcbef2dd" "104af15e-54ae-4c12-b293-8846be293203" "basic" "Basic" "4a3ea674-cff6-44de-b217-3befbe907a95" "2023-04-26 20:28:28.436054"
        , docProjectsColumnValues "e2b89bfc-2b4d-4c31-a92c-9ca6584c348c" "2d803b04-90d7-4e05-940f-5e887470b595" "gospeak-sql" "gospeak.sql" "11bd9544-d56a-43d7-9065-6f1f25addf8a" "2023-04-27 18:05:28.643297"
        ]
    , durationMs = 934
    , succeededAt = Time.zero
    , page = 1
    , expanded = Dict.empty
    , showQuery = False
    , documentMode = False
    , search = ""
    , sortBy = Nothing
    , fullScreen = False
    }
        |> StateSuccess


docColumn : SchemaName -> TableName -> ColumnName -> DatabaseQueryResultsColumn
docColumn schema table column =
    { name = column, ref = Just { table = ( schema, table ), column = Nel column [] } }


docCityColumnValues : Int -> String -> String -> String -> Int -> DatabaseQueryResultsRow
docCityColumnValues id name country_code district population =
    Dict.fromList [ ( "id", JsValue.Int id ), ( "name", JsValue.String name ), ( "country_code", JsValue.String country_code ), ( "district", JsValue.String district ), ( "population", JsValue.Int population ) ]


docProjectsColumnValues : String -> String -> String -> String -> String -> String -> DatabaseQueryResultsRow
docProjectsColumnValues id organization_id slug name created_by created_at =
    [ ( "id", id ), ( "organization_id", organization_id ), ( "slug", slug ), ( "name", name ), ( "created_by", created_by ), ( "created_at", created_at ) ] |> List.map (\( key, value ) -> ( key, JsValue.String value )) |> Dict.fromList


docUsersColumnValues : String -> String -> String -> String -> Maybe String -> Maybe String -> String -> Maybe String -> Maybe String -> Bool -> Maybe String -> String -> String -> String -> String -> Maybe String -> Dict String JsValue -> Dict String JsValue -> List JsValue -> DatabaseQueryResultsRow
docUsersColumnValues id slug name email provider provider_uid avatar github_username twitter_username is_admin hashed_password last_signin created_at updated_at confirmed_at deleted_at data provider_data tags =
    let
        str : List ( String, JsValue )
        str =
            [ ( "id", id ), ( "slug", slug ), ( "name", name ), ( "email", email ), ( "avatar", avatar ), ( "last_signin", last_signin ), ( "created_at", created_at ), ( "updated_at", updated_at ), ( "confirmed_at", confirmed_at ) ] |> List.map (\( key, value ) -> ( key, JsValue.String value ))

        strOpt : List ( String, JsValue )
        strOpt =
            [ ( "provider", provider ), ( "provider_uid", provider_uid ), ( "github_username", github_username ), ( "twitter_username", twitter_username ), ( "hashed_password", hashed_password ), ( "deleted_at", deleted_at ) ] |> List.map (\( key, value ) -> ( key, value |> Maybe.mapOrElse (\v -> JsValue.String v) JsValue.Null ))

        bool : List ( String, JsValue )
        bool =
            [ ( "is_admin", is_admin ) ] |> List.map (\( key, value ) -> ( key, JsValue.Bool value ))

        arr : List ( String, JsValue )
        arr =
            [ ( "tags", tags ) ] |> List.map (\( key, value ) -> ( key, JsValue.Array value ))

        obj : List ( String, JsValue )
        obj =
            [ ( "data", data ), ( "provider_data", provider_data ) ] |> List.map (\( key, value ) -> ( key, JsValue.Object value ))
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
    , columns = columns |> List.indexedMap (\i ( col, kind, nullable ) -> { index = i, name = col, kind = kind, nullable = nullable, default = Nothing, comment = Nothing, columns = Nothing, origins = [] }) |> Dict.fromListMap .name
    , primaryKey = Just { name = Just (name ++ "_pk"), columns = Nel (Nel "id" []) [], origins = [] }
    , uniques = []
    , indexes = []
    , checks = []
    , comment = Nothing
    , origins = []
    }


docRelation : ( SchemaName, TableName, ColumnName ) -> ( SchemaName, TableName, ColumnName ) -> Relation
docRelation ( fromSchema, fromTable, fromColumn ) ( toSchema, toTable, toColumn ) =
    Relation.new (fromTable ++ "." ++ fromColumn ++ "->" ++ toTable ++ "." ++ toColumn) { table = ( fromSchema, fromTable ), column = Nel fromColumn [] } { table = ( toSchema, toTable ), column = Nel toColumn [] } []



-- DOC HELPERS


docComponent : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
docComponent name render =
    ( name, \{ dataExplorerQueryDocState } -> render dataExplorerQueryDocState )


docComponentState : String -> (DocState -> Model) -> (DocState -> Model -> DocState) -> ( String, SharedDocState x -> Html (ElmBook.Msg (SharedDocState x)) )
docComponentState name get set =
    ( name, \{ dataExplorerQueryDocState } -> dataExplorerQueryDocState |> (\s -> get s |> (\m -> view (docUpdate s get set) (docOpenDropdown s) docOpenRow docDelete Time.zero s.openedDropdown docDefaultSchema docSources (docHtmlId ++ "-" ++ String.fromInt m.id) m)) )


docUpdate : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate s get set m =
    s |> get |> update docWrap m |> Tuple.first |> set s |> docSetState


docOpenDropdown : DocState -> HtmlId -> ElmBook.Msg (SharedDocState x)
docOpenDropdown s id =
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


docDropdown : HtmlId -> ElmBook.Msg state
docDropdown =
    \_ -> logAction "openDropdown"


docOpenRow : SourceInfo -> QueryBuilder.RowQuery -> ElmBook.Msg state
docOpenRow =
    \_ _ -> logAction "openRow"


docDelete : ElmBook.Msg state
docDelete =
    logAction "delete"
