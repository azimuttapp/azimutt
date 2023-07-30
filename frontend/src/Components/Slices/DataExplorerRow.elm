module Components.Slices.DataExplorerRow exposing (DocState, FailureState, Model, Msg(..), RowState(..), SharedDocState, SuccessState, doc, docInit, init, update, view)

import Components.Atoms.Icon as Icon
import Dict exposing (Dict)
import ElmBook
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, h2, p, span, text)
import Html.Attributes exposing (class, id, type_)
import Html.Events exposing (onClick)
import Libs.Html.Attributes exposing (ariaLabelledby, ariaModal, css, role)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel exposing (Nel)
import Libs.Task as T
import Libs.Time as Time
import Models.DatabaseQueryResults exposing (DatabaseQueryResultsColumn, DatabaseQueryResultsRow)
import Models.JsValue as JsValue exposing (JsValue)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.SourceId as SourceId
import Models.Project.TableId as TableId
import Models.Project.TableName exposing (TableName)
import Models.SourceInfo as SourceInfo exposing (SourceInfo)
import Services.QueryBuilder exposing (RowQuery)
import Time


type alias Model =
    { source : SourceInfo
    , query : RowQuery
    , startedAt : Time.Posix
    , state : RowState
    }


type RowState
    = StateLoading
    | StateSuccess SuccessState
    | StateFailure FailureState


type alias SuccessState =
    { columns : List DatabaseQueryResultsColumn
    , values : DatabaseQueryResultsRow
    , durationMs : Int
    , succeededAt : Time.Posix
    , documentMode : Bool
    }


type alias FailureState =
    { error : String, failedAt : Time.Posix }


type Msg
    = Noop



-- INIT


init : SourceInfo -> RowQuery -> Time.Posix -> Model
init source query startedAt =
    { source = source, query = query, startedAt = startedAt, state = StateLoading }



-- UPDATE


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update wrap msg model =
    case msg of
        _ ->
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
        , css
            [ "relative"
            , openDepth
                |> Maybe.mapOrElse
                    (\i ->
                        case i of
                            4 ->
                                "z-10"

                            3 ->
                                "z-11"

                            2 ->
                                "z-12"

                            1 ->
                                "z-13"

                            0 ->
                                "z-14"

                            _ ->
                                "z-10"
                    )
                    "z-10"
            ]
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
                            , openDepth
                                |> Maybe.mapOrElse
                                    (\i ->
                                        case i of
                                            4 ->
                                                "-translate-x-36"

                                            3 ->
                                                "-translate-x-27"

                                            2 ->
                                                "-translate-x-18"

                                            1 ->
                                                "-translate-x-9"

                                            _ ->
                                                "translate-x-0"
                                    )
                                    "translate-x-full"
                            ]
                        ]
                        [ viewSlideOverContent wrap close defaultSchema titleId openDepth model
                        ]
                    ]
                ]
            ]
        ]


viewSlideOverContent : (Msg -> msg) -> msg -> SchemaName -> HtmlId -> Maybe Int -> Model -> Html msg
viewSlideOverContent wrap close defaultSchema titleId openDepth model =
    div [ class "flex h-full flex-col overflow-y-auto bg-white py-6 shadow-xl" ]
        [ div [ class "px-4 sm:px-6" ]
            [ div [ class "flex items-start justify-between" ]
                [ h2 [ id titleId, class "text-base font-semibold leading-6 text-gray-900" ]
                    [ text "Panel title" ]
                , div [ class "ml-3 flex h-7 items-center" ]
                    [ button [ type_ "button", onClick close, class "relative rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" ]
                        [ span [ class "absolute -inset-2.5" ] []
                        , span [ class "sr-only" ] [ text "Close panel" ]
                        , Icon.solid Icon.X "h-6 w-6"
                        ]
                    ]
                ]
            ]
        , div [ class "relative mt-6 flex-1 px-4 sm:px-6" ]
            [ p [ onClick (wrap Noop) ] [ text "Your content" ]
            , p [] [ text (openDepth |> Maybe.mapOrElse (\i -> "Open in " ++ String.fromInt i) "Closed") ]
            , p []
                [ text
                    (case model.state of
                        StateLoading ->
                            "StateLoading " ++ TableId.show defaultSchema model.query.table

                        StateSuccess _ ->
                            "StateSuccess " ++ TableId.show defaultSchema model.query.table

                        StateFailure _ ->
                            "StateFailure " ++ TableId.show defaultSchema model.query.table
                    )
                ]
            ]
        ]



-- DOCUMENTATION


type alias SharedDocState x =
    { x | dataExplorerRowDocState : DocState }


type alias DocState =
    { success : Model, failure : Model, loading : Model, opened : List String }


docInit : DocState
docInit =
    { success = { docModel | state = StateSuccess docSuccessState }
    , failure = { docModel | state = StateFailure docFailureState }
    , loading = docModel
    , opened = []
    }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "DataExplorerRow"
        |> Chapter.renderStatefulComponentList
            [ docComponentState "success" .success (\s m -> { s | success = m })
            , docComponentState "failure" .failure (\s m -> { s | failure = m })
            , docComponentState "loading" .loading (\s m -> { s | loading = m })
            ]


docModel : Model
docModel =
    init docSource { table = ( "public", "city" ), primaryKey = Nel { column = Nel "id" [], kind = "int", value = "1" } [] } Time.zero


docSource : SourceInfo
docSource =
    SourceInfo.database Time.zero SourceId.zero ""


docSuccessState : SuccessState
docSuccessState =
    { columns = docCityColumns
    , values = docCityColumnValues 1 "Kabul" "AFG" "Kabol" 1780000
    , durationMs = 12
    , succeededAt = Time.zero
    , documentMode = False
    }


docFailureState : FailureState
docFailureState =
    { error = "Error: relation \"events\" does not exist\nError Code: 42P01", failedAt = Time.zero }


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


docComponentState : String -> (DocState -> Model) -> (DocState -> Model -> DocState) -> ( String, SharedDocState x -> Html (ElmBook.Msg (SharedDocState x)) )
docComponentState name get set =
    ( name
    , \{ dataExplorerRowDocState } ->
        let
            s : DocState
            s =
                dataExplorerRowDocState

            openDepth : Maybe Int
            openDepth =
                s.opened |> List.findIndex (\o -> o == name)
        in
        div []
            [ button [ type_ "button", onClick (docToggle name s), class "rounded-md bg-white px-3.5 py-2.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50" ]
                [ text (openDepth |> Maybe.mapOrElse (\_ -> "Close") "Open") ]
            , view (docUpdate s get set) (docToggle name s) "public" ("data-explorer-row-" ++ name) openDepth (get s)
            ]
    )


docUpdate : DocState -> (DocState -> Model) -> (DocState -> Model -> DocState) -> Msg -> ElmBook.Msg (SharedDocState x)
docUpdate s get set m =
    s |> get |> update docWrap m |> Tuple.first |> set s |> docSetState


docToggle : HtmlId -> DocState -> ElmBook.Msg (SharedDocState x)
docToggle id s =
    if s.opened |> List.any (\o -> o == id) then
        docSetState { s | opened = s.opened |> List.filter (\o -> o /= id) }

    else
        docSetState { s | opened = id :: s.opened }


docSetState : DocState -> ElmBook.Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | dataExplorerRowDocState = state })


docWrap : Msg -> ElmBook.Msg state
docWrap =
    \_ -> logAction "wrap"
