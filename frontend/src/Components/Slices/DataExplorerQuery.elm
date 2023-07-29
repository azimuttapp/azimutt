module Components.Slices.DataExplorerQuery exposing (DocState, Model, Msg(..), QueryState(..), SharedDocState, doc, initDocState)

import Components.Molecules.Pagination as Pagination
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, h1, p, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, classList, scope)
import Libs.Maybe as Maybe
import Libs.Nel exposing (Nel)
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
    { source : SourceInfo
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
    | Refresh -- run again the query
    | Edit -- put the query in sql editor, allow to update and run it
    | Export -- export results in csv or json (or copy in clipboard)
    | Cancel -- stop a query in a running state (only UI?)
    | Delete -- delete a query
    | OpenRow ColumnRef -- open a single row in sidebar
      -- used message ^^
    | ChangePage Int



-- INIT


init : SourceInfo -> String -> Time.Posix -> Model
init source query startedAt =
    { source = source, query = query, executions = Nel { startedAt = startedAt, state = StateRunning } [] }



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


view : (Msg -> msg) -> Model -> Html msg
view wrap model =
    div []
        [ h1 [ class "text-base font-semibold leading-6 text-gray-900" ] [ text model.source.name ]
        , p [ class "mt-2 text-sm text-gray-700" ] [ text model.query ]
        , case model.executions.head.state of
            StateRunning ->
                div [] [ text "StateRunning" ]

            StateCanceled _ ->
                div [] [ text "StateCanceled" ]

            StateSuccess res ->
                viewSuccess wrap res

            StateFailure _ ->
                div [] [ text "StateFailure" ]
        ]


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
    { success : Model }


initDocState : DocState
initDocState =
    { success = docModel }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "DataExplorerQuery"
        |> Chapter.renderStatefulComponentList
            [ docComponent "success" (\s -> view (\m -> docSetState { s | success = update (\_ -> logAction "msg") m s.success |> Tuple.first }) s.success)

            -- long lines
            , docComponent "failure" (\_ -> view (\_ -> logAction "msg") { docModel | executions = Nel { startedAt = Time.zero, state = StateFailure docFailureState } [] })
            , docComponent "running" (\_ -> view (\_ -> logAction "msg") { docModel | executions = Nel { startedAt = Time.zero, state = StateRunning } [] })
            , docComponent "canceled" (\_ -> view (\_ -> logAction "msg") { docModel | executions = Nel { startedAt = Time.zero, state = StateCanceled docQueryCanceled } [] })
            ]


docComponent : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
docComponent name render =
    ( name, \{ dataExplorerQueryDocState } -> render dataExplorerQueryDocState )


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | dataExplorerQueryDocState = state })


docModel : Model
docModel =
    { source = SourceInfo.database Time.zero SourceId.zero "azimutt_dev"
    , query = "SELECT * FROM city;"
    , executions = Nel { startedAt = Time.zero, state = StateSuccess docSuccessState } []
    }


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
