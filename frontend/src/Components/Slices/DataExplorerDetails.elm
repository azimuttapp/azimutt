module Components.Slices.DataExplorerDetails exposing (DocState, FailureState, Id, Model, Msg(..), SharedDocState, State(..), SuccessState, doc, docInit, init, update, view)

import Components.Atoms.Icon as Icon
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, dd, div, dt, h2, p, pre, span, text)
import Html.Attributes exposing (class, id, type_)
import Html.Events exposing (onClick)
import Libs.Html.Attributes exposing (ariaLabelledby, ariaModal, css, role)
import Libs.List as List
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel exposing (Nel)
import Libs.Result as Result
import Libs.Task as T
import Libs.Time as Time
import Models.DbSourceInfo as DbSourceInfo exposing (DbSourceInfo)
import Models.JsValue as JsValue exposing (JsValue)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId
import Models.Project.TableName exposing (TableName)
import Models.QueryResult exposing (QueryResult, QueryResultColumn, QueryResultRow, QueryResultSuccess)
import Services.Lenses exposing (mapState)
import Services.QueryBuilder exposing (RowQuery)
import Time


type alias Model =
    { id : Id
    , source : DbSourceInfo
    , query : RowQuery
    , state : State
    }


type alias Id =
    Int


type State
    = StateLoading
    | StateFailure FailureState
    | StateSuccess SuccessState


type alias FailureState =
    { error : String, startedAt : Time.Posix, failedAt : Time.Posix }


type alias SuccessState =
    { columns : List QueryResultColumn
    , values : QueryResultRow
    , startedAt : Time.Posix
    , succeededAt : Time.Posix
    , documentMode : Bool
    }


type Msg
    = GotResult QueryResult
    | Noop



-- INIT


init : Id -> DbSourceInfo -> RowQuery -> Model
init id source query =
    { id = id, source = source, query = query, state = StateLoading }


initFailure : Time.Posix -> Time.Posix -> String -> State
initFailure started finished err =
    StateFailure { error = err, startedAt = started, failedAt = finished }


initSuccess : Time.Posix -> Time.Posix -> QueryResultSuccess -> State
initSuccess started finished res =
    StateSuccess
        { columns = res.columns
        , values = res.rows |> List.head |> Maybe.withDefault Dict.empty
        , startedAt = started
        , succeededAt = finished
        , documentMode = False
        }



-- UPDATE


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update wrap msg model =
    case msg of
        GotResult res ->
            ( model |> mapState (\_ -> res.result |> Result.fold (initFailure res.started res.finished) (initSuccess res.started res.finished)), Cmd.none )

        _ ->
            -- FIXME to remove
            ( model, Noop |> wrap |> T.send )



-- VIEW


view : (Msg -> msg) -> msg -> SchemaName -> HtmlId -> Maybe Int -> Model -> Html msg
view wrap close defaultSchema htmlId openDepth model =
    let
        titleId : HtmlId
        titleId =
            htmlId ++ "-title"
    in
    div
        [ ariaLabelledby titleId
        , role "dialog"
        , ariaModal True
        , css [ "relative", openDepth |> Maybe.andThen (\i -> [ "z-16", "z-15", "z-14", "z-13", "z-12", "z-11" ] |> List.get i) |> Maybe.withDefault "z-10" ]
        ]
        [ div [ class "fixed inset-0 overflow-hidden pointer-events-none" ]
            [ div [ class "absolute inset-0 overflow-hidden" ]
                [ div [ class "pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10" ]
                    [ {-
                         Slide-over panel, show/hide based on slide-over state.

                         Entering: "transform transition ease-in-out duration-500 sm:duration-700"
                           From: "translate-x-full"
                           To: "translate-x-0"
                         Leaving: "transform transition ease-in-out duration-500 sm:duration-700"
                           From: "translate-x-0"
                           To: "translate-x-full"
                      -}
                      div
                        [ css
                            [ "pointer-events-auto w-screen max-w-md transform transition ease-in-out duration-200 sm:duration-400"
                            , openDepth |> Maybe.andThen (\i -> [ "translate-x-0", "-translate-x-6", "-translate-x-12", "-translate-x-16", "-translate-x-20" ] |> List.get i) |> Maybe.withDefault "translate-x-full"
                            ]
                        ]
                        [ viewSlideOverContent wrap close defaultSchema titleId model
                        ]
                    ]
                ]
            ]
        ]


viewSlideOverContent : (Msg -> msg) -> msg -> SchemaName -> HtmlId -> Model -> Html msg
viewSlideOverContent wrap close defaultSchema titleId model =
    div [ class "flex h-full flex-col overflow-y-auto bg-white py-6 shadow-xl" ]
        [ div [ class "px-4 sm:px-6" ]
            [ div [ class "flex items-start justify-between" ]
                [ h2 [ onClick (wrap Noop), id titleId, class "text-base font-semibold leading-6 text-gray-900" ]
                    [ text (TableId.show defaultSchema model.query.table) ]
                , div [ class "ml-3 flex h-7 items-center" ]
                    [ button [ type_ "button", onClick close, class "relative rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" ]
                        [ span [ class "absolute -inset-2.5" ] []
                        , span [ class "sr-only" ] [ text "Close panel" ]
                        , Icon.solid Icon.X "h-6 w-6"
                        ]
                    ]
                ]
            ]
        , div [ class "relative flex-1 mt-3 space-y-3 px-4 sm:px-6" ]
            (case model.state of
                StateLoading ->
                    [ text "Loading... " ]

                StateFailure res ->
                    [ p [ class "mt-3 text-sm font-semibold text-gray-900" ] [ text "Error" ]
                    , pre [ class "px-6 py-4 block text-sm whitespace-pre overflow-x-auto rounded bg-red-50 border border-red-200" ] [ text res.error ]
                    ]

                StateSuccess res ->
                    res.columns
                        |> List.map
                            (\col ->
                                div []
                                    [ dt [ class "text-sm font-medium text-gray-500 sm:w-40 sm:flex-shrink-0" ] [ text col.name ]
                                    , dd [ class "text-sm text-gray-900 sm:col-span-2" ] [ JsValue.view (res.values |> Dict.get col.name) ]
                                    ]
                            )
            )
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | dataExplorerDetailsDocState : DocState }


type alias DocState =
    { details : List Model }


docInit : DocState
docInit =
    { details = [] }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "DataExplorerDetails"
        |> Chapter.renderStatefulComponentList
            [ ( "app"
              , \{ dataExplorerDetailsDocState } ->
                    let
                        s : DocState
                        s =
                            dataExplorerDetailsDocState
                    in
                    div []
                        [ docButton "Open loading" (docOpen docModel s)
                        , docButton "Open failure" (docOpen { docModel | state = StateFailure docFailureState } s)
                        , docButton "Open success" (docOpen { docModel | state = StateSuccess docSuccessState } s)
                        , div []
                            (s.details
                                |> List.indexedMap
                                    (\i m ->
                                        div [ class "mt-1" ]
                                            [ view (docUpdate i s) (docClose i s) "public" ("data-explorer-details-" ++ String.fromInt i) (Just i) m
                                            , docButton ("Close " ++ String.fromInt i) (docClose i s)
                                            ]
                                    )
                                |> List.reverse
                            )
                        ]
              )
            ]


docButton : String -> ElmBook.Msg (SharedDocState x) -> Html (ElmBook.Msg (SharedDocState x))
docButton name msg =
    button [ type_ "button", onClick msg, class "mr-3 rounded-md bg-white px-3.5 py-2.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50" ] [ text name ]


docModel : Model
docModel =
    init 1 docSource { table = ( "public", "city" ), primaryKey = Nel { column = Nel "id" [], kind = "int", value = "1" } [] }


docSource : DbSourceInfo
docSource =
    DbSourceInfo.zero


docFailureState : FailureState
docFailureState =
    { error = "Error: relation \"events\" does not exist\nError Code: 42P01", startedAt = Time.zero, failedAt = Time.zero }


docSuccessState : SuccessState
docSuccessState =
    { columns = [ "id", "name", "country_code", "district", "population" ] |> List.map (docColumn "public" "city")
    , values = docCityColumnValues 1 "Kabul" "AFG" "Kabol" 1780000
    , startedAt = Time.zero
    , succeededAt = Time.zero
    , documentMode = False
    }


docColumn : SchemaName -> TableName -> ColumnName -> QueryResultColumn
docColumn schema table column =
    { name = column, ref = Just { table = ( schema, table ), column = Nel column [] } }


docCityColumnValues : Int -> String -> String -> String -> Int -> QueryResultRow
docCityColumnValues id name country_code district population =
    Dict.fromList [ ( "id", JsValue.Int id ), ( "name", JsValue.String name ), ( "country_code", JsValue.String country_code ), ( "district", JsValue.String district ), ( "population", JsValue.Int population ) ]



-- DOC HELPERS


docUpdate : Int -> DocState -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate i s msg =
    docSetState { s | details = s.details |> List.mapAt i (update docWrap msg >> Tuple.first) }


docOpen : Model -> DocState -> ElmBook.Msg (SharedDocState x)
docOpen m s =
    docSetState { s | details = m :: s.details }


docClose : Int -> DocState -> ElmBook.Msg (SharedDocState x)
docClose i s =
    docSetState { s | details = s.details |> List.removeAt i }


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | dataExplorerDetailsDocState = state })


docWrap : Msg -> ElmBook.Msg state
docWrap =
    \_ -> logAction "wrap"
