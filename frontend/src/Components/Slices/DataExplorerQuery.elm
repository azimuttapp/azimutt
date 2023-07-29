module Components.Slices.DataExplorerQuery exposing (CanceledState, DocState, FailureState, Model, Msg(..), QueryState(..), SharedDocState, SuccessState, doc, initDocState)

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
import Libs.Html.Attributes exposing (ariaExpanded, ariaHaspopup, css)
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel exposing (Nel)
import Libs.Tailwind exposing (focus)
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


type alias Model =
    { id : Int
    , source : SourceInfo
    , query : String
    , executions : Nel { startedAt : Time.Posix, state : QueryState }
    }


type QueryState
    = StateRunning
    | StateCanceled CanceledState
    | StateSuccess SuccessState
    | StateFailure FailureState


type alias CanceledState =
    { canceledAt : Time.Posix }


type alias SuccessState =
    { columns : List DatabaseQueryResultsColumn
    , rows : List DatabaseQueryResultsRow
    , durationMs : Int
    , succeededAt : Time.Posix
    , page : Int
    , documentMode : Bool
    , search : String
    , sortBy : Maybe String
    , fullScreen : Bool
    }


type alias FailureState =
    { error : String, failedAt : Time.Posix }


type Msg
    = FullScreen
    | ToggleQuery
    | Refresh -- run again the query
    | Export -- export results in csv or json (or copy in clipboard)
    | Cancel -- stop a query in a running state (only UI?)
    | Remove -- delete a query
    | OpenRow ColumnRef -- open a single row in sidebar
      -- used message ^^
    | ChangePage Int



-- INIT


init : Int -> SourceInfo -> String -> Time.Posix -> Model
init id source query startedAt =
    { id = id, source = source, query = query, executions = Nel { startedAt = startedAt, state = StateRunning } [] }



-- UPDATE


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update wrap msg model =
    case msg of
        ChangePage p ->
            ( model |> mapExecutions (mapHead (mapState (mapSuccess (\s -> { s | page = p })))), Cmd.none )

        _ ->
            -- FIXME to remove
            ( model, Cmd.none )


mapSuccess : (SuccessState -> SuccessState) -> QueryState -> QueryState
mapSuccess f state =
    case state of
        StateSuccess s ->
            StateSuccess (f s)

        _ ->
            state



-- VIEW


view : (Msg -> msg) -> (HtmlId -> msg) -> Time.Posix -> HtmlId -> Model -> Html msg
view wrap openDropdown now openedDropdown model =
    case model.executions.head.state of
        StateRunning ->
            viewCard model.source.name
                (p [ class "mt-1 text-sm text-gray-500 space-x-2" ]
                    [ span [ class "font-bold text-amber-500" ] [ text "Running..." ]
                    , span [ class "relative inline-flex h-2 w-2" ]
                        [ span [ class "animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75" ] []
                        , span [ class "relative inline-flex rounded-full h-2 w-2 bg-amber-500" ] []
                        ]
                    , span [] [ text (String.fromInt (Time.posixToMillis now - Time.posixToMillis model.executions.head.startedAt) ++ " ms") ]
                    ]
                )
                (div [ class "mt-3" ] [ viewQuery model.query ])
                (div [ class "relative flex space-x-1 text-left" ] [ viewActionButton "Cancel execution" Icon.XCircle ])

        StateCanceled res ->
            viewCard model.source.name
                (p [ class "mt-1 text-sm text-gray-500 space-x-2" ]
                    [ span [ class "font-bold" ] [ text "Canceled!" ]
                    , span [] [ text (String.fromInt (Time.posixToMillis res.canceledAt - Time.posixToMillis model.executions.head.startedAt) ++ " ms") ]
                    ]
                )
                (div [ class "mt-3" ] [ viewQuery model.query ])
                (div [ class "relative flex space-x-1 text-left" ] [ viewActionButton "Remove" Icon.Trash ])

        StateSuccess res ->
            let
                dropdownId : HtmlId
                dropdownId =
                    "data-explorer-query-" ++ String.fromInt model.id ++ "-settings"
            in
            viewCard model.source.name
                (p [ class "mt-1 text-sm text-gray-500 space-x-1" ]
                    [ span [ class "font-bold text-green-500" ] [ text "Success" ]
                    , span [] [ text ("(" ++ (res.rows |> List.length |> String.fromInt) ++ " rows)") ]
                    , span [] [ text (String.fromInt (Time.posixToMillis res.succeededAt - Time.posixToMillis model.executions.head.startedAt) ++ " ms") ]
                    ]
                )
                (div [ class "mt-3" ] [ viewSuccess wrap res ])
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
                            , Icon.solid Icon.DotsVertical ""
                            ]
                    )
                    (\_ ->
                        div []
                            ([ { label = "Show query", content = ContextMenu.Simple { action = wrap ToggleQuery } }
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
                             , { label = "Remove", content = ContextMenu.Simple { action = wrap Remove } }
                             ]
                                |> List.map ContextMenu.btnSubmenu
                            )
                    )
                )

        StateFailure res ->
            viewCard model.source.name
                (p [ class "mt-1 text-sm text-gray-500 space-x-1" ]
                    [ span [ class "font-bold text-red-500" ] [ text "Failed" ]
                    , span [] [ text (String.fromInt (Time.posixToMillis res.failedAt - Time.posixToMillis model.executions.head.startedAt) ++ " ms") ]
                    ]
                )
                (div []
                    [ p [ class "mt-3 text-sm font-semibold text-gray-900" ] [ text "Error" ]
                    , pre [ class "px-6 py-4 block whitespace-pre overflow-x-scroll rounded bg-red-50 border border-red-200" ] [ text res.error ]
                    , p [ class "mt-3 text-sm font-semibold text-gray-900" ] [ text "SQL" ]
                    , viewQuery model.query
                    ]
                )
                (div [ class "relative flex space-x-1 text-left" ]
                    [ viewActionButton "Run again execution" Icon.Refresh
                    , viewActionButton "Remove" Icon.Trash
                    ]
                )


viewCard : String -> Html msg -> Html msg -> Html msg -> Html msg
viewCard cardTitle cardSubtitle cardBody cardActions =
    div [ class "bg-white" ]
        [ div [ class "flex space-x-3" ]
            [ div [ class "min-w-0 flex-1" ]
                [ p [ class "text-sm font-semibold text-gray-900" ] [ text cardTitle ]
                , cardSubtitle
                ]
            , div [ class "flex flex-shrink-0 self-center" ] [ cardActions ]
            ]
        , cardBody
        ]


viewQuery : String -> Html msg
viewQuery query =
    pre [ class "px-6 py-4 block whitespace-pre overflow-x-scroll rounded bg-gray-50 border border-gray-200" ] [ text query ]


viewActionButton : String -> Icon -> Html msg
viewActionButton name icon =
    button [ type_ "button", title name, class "flex items-center rounded-full text-gray-400 hover:text-gray-600" ]
        [ span [ class "sr-only" ] [ text name ], Icon.outline icon "h-5 w-5" ]


viewSuccess : (Msg -> msg) -> SuccessState -> Html msg
viewSuccess wrap success =
    let
        pagination : Pagination.Model
        pagination =
            { currentPage = success.page, pageSize = 10, totalItems = success.rows |> List.length }

        pageRows : List ( Int, DatabaseQueryResultsRow )
        pageRows =
            Pagination.paginate success.rows pagination
    in
    div []
        [ viewTable success.columns pageRows
        , Pagination.view (\p -> ChangePage p |> wrap) pagination
        ]


viewTable : List DatabaseQueryResultsColumn -> List ( Int, DatabaseQueryResultsRow ) -> Html msg
viewTable columns rows =
    div [ class "flow-root" ]
        [ div [ class "-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8" ]
            [ div [ class "inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8" ]
                [ table [ class "min-w-full divide-y divide-gray-300" ]
                    [ thead []
                        [ tr [ class "bg-gray-100" ]
                            (th [ scope "col", class "text-left text-sm font-semibold text-gray-900" ] [ text "#" ]
                                :: (columns |> List.map (\c -> th [ scope "col", class "text-left text-sm font-semibold text-gray-900" ] [ text c.name ]))
                            )
                        ]
                    , tbody [ class "divide-y divide-gray-200" ]
                        (rows
                            |> List.map
                                (\( i, r ) ->
                                    tr [ class "hover:bg-gray-100", classList [ ( "bg-gray-50", modBy 2 i == 1 ) ] ]
                                        (td [ class "whitespace-nowrap text-sm text-gray-900" ] [ text (i |> String.fromInt) ]
                                            :: (columns |> List.map (\c -> td [ class "whitespace-nowrap text-sm text-gray-500" ] [ text (r |> Dict.get c.name |> Maybe.mapOrElse JsValue.format "") ]))
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
    { openedDropdown : HtmlId, success : Model }


initDocState : DocState
initDocState =
    { openedDropdown = "", success = docModel }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "DataExplorerQuery"
        |> Chapter.renderStatefulComponentList
            [ docComponentState "success" .success (\s m -> { s | success = m })

            -- long lines
            , docComponent "failure" (\s -> view docWrap docOpenDropdown Time.zero s.openedDropdown { docModel | executions = Nel { startedAt = Time.zero, state = StateFailure docFailureState } [] })
            , docComponent "running" (\s -> view docWrap docOpenDropdown Time.zero s.openedDropdown { docModel | executions = Nel { startedAt = Time.zero, state = StateRunning } [] })
            , docComponent "canceled" (\s -> view docWrap docOpenDropdown Time.zero s.openedDropdown { docModel | executions = Nel { startedAt = Time.zero, state = StateCanceled docQueryCanceled } [] })
            ]


docModel : Model
docModel =
    { id = 0
    , source = SourceInfo.database Time.zero SourceId.zero "azimutt_dev"
    , query = docComplexQuery -- "SELECT * FROM city;"
    , executions = Nel { startedAt = Time.zero, state = StateSuccess docSuccessState } []
    }


docComplexQuery : String
docComplexQuery =
    """SELECT u.id, u.name, u.avatar, u.email, count(distinct to_char(e.created_at, 'yyyy-mm-dd')) as active_days, count(*) as nb_events, max(e.created_at) as last_activity
FROM events e JOIN users u on u.id = e.created_by
GROUP BY u.id
HAVING count(distinct to_char(e.created_at, 'yyyy-mm-dd')) >= 5 AND max(e.created_at) < NOW() - INTERVAL '30 days'
ORDER BY last_activity DESC;"""


docSuccessState : SuccessState
docSuccessState =
    { columns = docCityColumns
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
    , documentMode = False
    , search = ""
    , sortBy = Nothing
    , fullScreen = False
    }


docFailureState : FailureState
docFailureState =
    { error = "Error: relation \"events\" does not exist\nError Code: 42P01", failedAt = Time.zero }


docQueryCanceled : CanceledState
docQueryCanceled =
    { canceledAt = Time.zero }


docCityColumns : List DatabaseQueryResultsColumn
docCityColumns =
    [ "id", "name", "country_code", "district", "population" ] |> List.map (docColumn "public" "city")


docColumn : SchemaName -> TableName -> ColumnName -> DatabaseQueryResultsColumn
docColumn schema table column =
    { name = column, ref = Just { table = ( schema, table ), column = Nel column [] } }


docCityColumnValues : Int -> String -> String -> String -> Int -> DatabaseQueryResultsRow
docCityColumnValues id name country_code district population =
    Dict.fromList [ ( "id", JsValue.Int id ), ( "name", JsValue.String name ), ( "country_code", JsValue.String country_code ), ( "district", JsValue.String district ), ( "population", JsValue.Int population ) ]



-- DOC HELPERS


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | dataExplorerQueryDocState = state })


docComponent : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
docComponent name render =
    ( name, \{ dataExplorerQueryDocState } -> render dataExplorerQueryDocState )


docComponentState : String -> (DocState -> Model) -> (DocState -> Model -> DocState) -> ( String, SharedDocState x -> Html (ElmBook.Msg (SharedDocState x)) )
docComponentState name get set =
    ( name, \{ dataExplorerQueryDocState } -> dataExplorerQueryDocState |> (\s -> view (docUpdate s get set) (docUpdateDropdown s) Time.zero s.openedDropdown (get s)) )


docUpdate : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate s get set m =
    s |> get |> update docWrap m |> Tuple.first |> set s |> docSetState


docUpdateDropdown : DocState -> HtmlId -> ElmBook.Msg (SharedDocState x)
docUpdateDropdown s id =
    if s.openedDropdown == id then
        docSetState { s | openedDropdown = "" }

    else
        docSetState { s | openedDropdown = id }


docWrap : Msg -> ElmBook.Msg state
docWrap =
    \_ -> logAction "wrap"


docOpenDropdown : HtmlId -> ElmBook.Msg state
docOpenDropdown =
    \_ -> logAction "openDropdown"
