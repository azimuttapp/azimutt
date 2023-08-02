module Models.DatabaseQueryResults exposing (DatabaseQueryResults, DatabaseQueryResultsRow, QueryResultColumn, decode)

import Dict exposing (Dict)
import Json.Decode as Decode
import Libs.Json.Decode as Decode
import Models.JsValue as JsValue exposing (JsValue)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Time


type alias QueryResult =
    { query : String
    , result : Result String QueryResultSuccess
    , started : Time.Posix
    , finished : Time.Posix
    }


type alias QueryResultSuccess =
    { columns : List QueryResultColumn
    , rows : List DatabaseQueryResultsRow
    }


type alias DatabaseQueryResults =
    { query : String
    , columns : List QueryResultColumn
    , rows : List DatabaseQueryResultsRow
    }


type alias QueryResultColumn =
    { name : String, ref : Maybe ColumnRef }


type alias DatabaseQueryResultsRow =
    Dict String JsValue


decode : Decode.Decoder DatabaseQueryResults
decode =
    Decode.map3 DatabaseQueryResults
        (Decode.field "query" Decode.string)
        (Decode.field "columns" (Decode.list decodeColumn))
        (Decode.field "rows" (Decode.list (Decode.dict JsValue.decode)))


decodeColumn : Decode.Decoder QueryResultColumn
decodeColumn =
    Decode.map2 QueryResultColumn
        (Decode.field "name" Decode.string)
        (Decode.maybeField "ref" ColumnRef.decode)
