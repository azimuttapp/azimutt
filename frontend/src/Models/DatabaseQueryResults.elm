module Models.DatabaseQueryResults exposing (DatabaseQueryResults, DatabaseQueryResultsColumn, decode)

import Dict exposing (Dict)
import Json.Decode as Decode
import Libs.Json.Decode as Decode
import Models.JsValue as JsValue exposing (JsValue)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)


type alias DatabaseQueryResults =
    { query : String
    , columns : List DatabaseQueryResultsColumn
    , rows : List (Dict String JsValue)
    }


type alias DatabaseQueryResultsColumn =
    { name : String, ref : Maybe ColumnRef }


decode : Decode.Decoder DatabaseQueryResults
decode =
    Decode.map3 DatabaseQueryResults
        (Decode.field "query" Decode.string)
        (Decode.field "columns" (Decode.list decodeColumn))
        (Decode.field "rows" (Decode.list (Decode.dict JsValue.decode)))


decodeColumn : Decode.Decoder DatabaseQueryResultsColumn
decodeColumn =
    Decode.map2 DatabaseQueryResultsColumn
        (Decode.field "name" Decode.string)
        (Decode.maybeField "ref" ColumnRef.decode)
