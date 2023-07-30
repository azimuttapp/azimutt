module Components.Slices.DataExplorerQuery exposing (CanceledState, DocState, FailureState, Model, Msg(..), QueryId, QueryState(..), RowIndex, SharedDocState, SuccessState, doc, docInit, docSuccessState1, docSuccessState2, init, update, view)

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
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel exposing (Nel)
import Libs.Tailwind exposing (focus)
import Libs.Task as T
import Libs.Time as Time
import Models.DatabaseQueryResults exposing (DatabaseQueryResultsColumn, DatabaseQueryResultsRow)
import Models.JsValue as JsValue exposing (JsValue)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.SourceId as SourceId
import Models.Project.TableName exposing (TableName)
import Models.SourceInfo as SourceInfo exposing (SourceInfo)
import Services.Lenses exposing (mapExecutions, mapHead, mapState)
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


view : (Msg -> msg) -> (HtmlId -> msg) -> msg -> Time.Posix -> HtmlId -> HtmlId -> Model -> Html msg
view wrap openDropdown deleteQuery now openedDropdown htmlId model =
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
                (div [ class "mt-3" ] [ viewQuery model.query ])
                (div [ class "relative flex space-x-1 text-left" ] [ viewActionButton "Cancel execution" Icon.XCircle ])

        StateCanceled res ->
            viewCard
                [ p [ class "text-sm font-semibold text-gray-900" ] [ text ("#" ++ String.fromInt model.id ++ " " ++ model.source.name) ]
                , p [ class "mt-1 text-sm text-gray-500 space-x-2" ]
                    [ span [ class "font-bold" ] [ text "Canceled!" ]
                    , span [] [ text (String.fromInt (Time.posixToMillis res.canceledAt - Time.posixToMillis model.executions.head.startedAt) ++ " ms") ]
                    ]
                ]
                (div [ class "mt-3" ] [ viewQuery model.query ])
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
                    , viewQuery model.query
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
                            , viewQuery model.query
                            ]

                      else
                        div [] []
                    , div [ class "mt-3" ] [ viewSuccess wrap res ]
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
                            ([ { label = Bool.cond res.showQuery "Hide query" "Show query", content = ContextMenu.Simple { action = wrap ToggleQuery } }
                             , { label = "Explore in full screen", content = ContextMenu.Simple { action = wrap FullScreen } }
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


viewQuery : String -> Html msg
viewQuery query =
    pre [ class "px-6 py-4 block text-sm whitespace-pre overflow-x-auto rounded bg-gray-50 border border-gray-200" ] [ text query ]


viewActionButton : String -> Icon -> Html msg
viewActionButton name icon =
    button [ type_ "button", title name, class "flex items-center rounded-full text-gray-400 hover:text-gray-600" ]
        [ span [ class "sr-only" ] [ text name ], Icon.outline icon "w-4 h-4" ]


viewSuccess : (Msg -> msg) -> SuccessState -> Html msg
viewSuccess wrap res =
    let
        pagination : Pagination.Model
        pagination =
            { currentPage = res.page, pageSize = 10, totalItems = res.rows |> List.length }

        pageRows : List ( RowIndex, DatabaseQueryResultsRow )
        pageRows =
            Pagination.paginate res.rows pagination
    in
    div []
        [ viewTable wrap res.columns pageRows res.expanded
        , Pagination.view (\p -> ChangePage p |> wrap) pagination
        ]


viewTable : (Msg -> msg) -> List DatabaseQueryResultsColumn -> List ( RowIndex, DatabaseQueryResultsRow ) -> Dict RowIndex Bool -> Html msg
viewTable wrap columns rows expanded =
    div [ class "flow-root" ]
        [ div [ class "overflow-x-auto" ]
            [ div [ class "inline-block min-w-full align-middle" ]
                [ table [ class "min-w-full divide-y divide-gray-300" ]
                    [ thead []
                        [ tr [ class "bg-gray-100" ]
                            (th [ scope "col", class "px-1 text-left text-sm font-semibold text-gray-900" ] [ text "#" ]
                                :: (columns |> List.map (\c -> th [ scope "col", class "px-1 text-left text-sm font-semibold text-gray-900" ] [ text c.name ]))
                            )
                        ]
                    , tbody []
                        (rows
                            |> List.map
                                (\( i, r ) ->
                                    tr [ class "hover:bg-gray-100", classList [ ( "bg-gray-50", modBy 2 i == 1 ) ] ]
                                        (td [ class "px-1 text-sm text-gray-900" ] [ text (i |> String.fromInt) ]
                                            :: (columns
                                                    |> List.map (\c -> r |> Dict.get c.name)
                                                    |> List.map
                                                        (\value ->
                                                            if value |> Maybe.any (\v -> JsValue.isArray v || JsValue.isObject v) then
                                                                td [ onClick (ExpandRow i |> wrap), class "px-1 text-sm text-gray-500 whitespace-nowrap max-w-xs truncate cursor-pointer" ]
                                                                    [ if expanded |> Dict.getOrElse i False then
                                                                        JsValue.viewRaw value

                                                                      else
                                                                        JsValue.view value
                                                                    ]

                                                            else
                                                                td [ class "px-1 text-sm text-gray-500 whitespace-nowrap max-w-xs truncate" ] [ JsValue.view value ]
                                                        )
                                               )
                                        )
                                )
                        )
                    ]
                ]
            ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | dataExplorerQueryDocState : DocState }


type alias DocState =
    { openedDropdown : HtmlId, success : Model, longLines : Model }


docInit : DocState
docInit =
    { openedDropdown = ""
    , success = docModel
    , longLines = { docModel | id = 2, executions = Nel { startedAt = Time.zero, state = StateSuccess docSuccessState2 } [] }
    }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "DataExplorerQuery"
        |> Chapter.renderStatefulComponentList
            [ docComponentState "success" .success (\s m -> { s | success = m })
            , docComponentState "long lines & json" .longLines (\s m -> { s | longLines = m })
            , docComponent "failure" (\s -> view docWrap docDropdown docDelete Time.zero s.openedDropdown docHtmlId { docModel | id = 3, executions = Nel { startedAt = Time.zero, state = StateFailure docFailureState } [] })
            , docComponent "running" (\s -> view docWrap docDropdown docDelete Time.zero s.openedDropdown docHtmlId { docModel | id = 4, executions = Nel { startedAt = Time.zero, state = StateRunning } [] })
            , docComponent "canceled" (\s -> view docWrap docDropdown docDelete Time.zero s.openedDropdown docHtmlId { docModel | id = 5, executions = Nel { startedAt = Time.zero, state = StateCanceled docQueryCanceled } [] })
            ]


docHtmlId : HtmlId
docHtmlId =
    "data-explorer-query"


docModel : Model
docModel =
    { id = 1
    , source = SourceInfo.database Time.zero SourceId.zero "azimutt_dev"
    , query = docComplexQuery -- "SELECT * FROM city;"
    , executions = Nel { startedAt = Time.zero, state = StateSuccess docSuccessState1 } []
    }


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


docQueryCanceled : CanceledState
docQueryCanceled =
    { canceledAt = Time.zero }


docFailureState : FailureState
docFailureState =
    { error = "Error: relation \"events\" does not exist\nError Code: 42P01", failedAt = Time.zero }


docSuccessState1 : SuccessState
docSuccessState1 =
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


docSuccessState2 : SuccessState
docSuccessState2 =
    { columns = [ "id", "slug", "name", "email", "provider", "provider_uid", "avatar", "github_username", "twitter_username", "is_admin", "hashed_password", "last_signin", "created_at", "updated_at", "confirmed_at", "deleted_at", "data", "onboarding", "provider_data", "tags" ] |> List.map (docColumn "" "users")
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


docColumn : SchemaName -> TableName -> ColumnName -> DatabaseQueryResultsColumn
docColumn schema table column =
    { name = column, ref = Just { table = ( schema, table ), column = Nel column [] } }


docCityColumnValues : Int -> String -> String -> String -> Int -> DatabaseQueryResultsRow
docCityColumnValues id name country_code district population =
    Dict.fromList [ ( "id", JsValue.Int id ), ( "name", JsValue.String name ), ( "country_code", JsValue.String country_code ), ( "district", JsValue.String district ), ( "population", JsValue.Int population ) ]


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



-- DOC HELPERS


docComponent : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
docComponent name render =
    ( name, \{ dataExplorerQueryDocState } -> render dataExplorerQueryDocState )


docComponentState : String -> (DocState -> Model) -> (DocState -> Model -> DocState) -> ( String, SharedDocState x -> Html (ElmBook.Msg (SharedDocState x)) )
docComponentState name get set =
    ( name, \{ dataExplorerQueryDocState } -> dataExplorerQueryDocState |> (\s -> get s |> (\m -> view (docUpdate s get set) (docOpenDropdown s) docDelete Time.zero s.openedDropdown (docHtmlId ++ "-" ++ String.fromInt m.id) m)) )


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


docDelete : ElmBook.Msg state
docDelete =
    logAction "delete"
