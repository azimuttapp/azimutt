module Components.Slices.DataExplorerRow exposing (FailureState, Model, Msg(..), RowState(..), SuccessState, doc, init, update, view)

import Dict exposing (Dict)
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, text)
import Html.Events exposing (onClick)
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


view : (Msg -> msg) -> Model -> Html msg
view wrap model =
    div []
        [ text "Data Explorer Row"
        , div [ onClick (wrap Noop) ] [ text ("Loading " ++ TableId.show "" model.query.table) ]
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "DataExplorerRow"
        |> Chapter.renderComponentList
            [ ( "success", view (\_ -> logAction "msg") docModel )
            , ( "failure", view (\_ -> logAction "msg") { docModel | state = StateFailure docFailureState } )
            , ( "loading", view (\_ -> logAction "msg") { docModel | state = StateLoading } )
            ]


docModel : Model
docModel =
    { source = SourceInfo.database Time.zero SourceId.zero ""
    , query = { table = ( "public", "city" ), primaryKey = Nel { column = Nel "id" [], kind = "int", value = "1" } [] }
    , startedAt = Time.zero
    , state = StateSuccess docSuccessState
    }


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
