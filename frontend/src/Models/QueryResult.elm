module Models.QueryResult exposing (QueryResult, QueryResultColumn, QueryResultRow, QueryResultSuccess, decode)

import Dict exposing (Dict)
import Json.Decode as Decode
import Libs.Json.Decode as Decode
import Libs.Result as Result
import Libs.Time as Time
import Models.JsValue as JsValue exposing (JsValue)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Time


type alias QueryResult =
    { context : String
    , query : String
    , result : Result String QueryResultSuccess
    , started : Time.Posix
    , finished : Time.Posix
    }


type alias QueryResultSuccess =
    { columns : List QueryResultColumn
    , rows : List QueryResultRow
    }


type alias QueryResultColumn =
    { name : String, ref : Maybe ColumnRef }


type alias QueryResultRow =
    Dict String JsValue


decode : Decode.Decoder QueryResult
decode =
    Decode.map5 QueryResult
        (Decode.field "context" Decode.string)
        (Decode.field "query" Decode.string)
        (Decode.field "result" (Result.decode Decode.string decodeSuccess))
        (Decode.field "started" Time.decode)
        (Decode.field "finished" Time.decode)


decodeSuccess : Decode.Decoder QueryResultSuccess
decodeSuccess =
    Decode.map2 QueryResultSuccess
        (Decode.field "columns" (Decode.list decodeColumn))
        (Decode.field "rows" (Decode.list (Decode.dict JsValue.decode)))


decodeColumn : Decode.Decoder QueryResultColumn
decodeColumn =
    Decode.map2 QueryResultColumn
        (Decode.field "name" Decode.string)
        (Decode.maybeField "ref" ColumnRef.decode)
