module Models.DatabaseQueryResults exposing (DatabaseQueryResults, decode)

import Dict exposing (Dict)
import Json.Decode as Decode
import Models.JsValue as JsValue exposing (JsValue)


type alias DatabaseQueryResults =
    { query : String, columns : List String, rows : List (Dict String JsValue) }


decode : Decode.Decoder DatabaseQueryResults
decode =
    Decode.map3 DatabaseQueryResults
        (Decode.field "query" Decode.string)
        (Decode.field "columns" (Decode.list Decode.string))
        (Decode.field "rows" (Decode.list (Decode.dict JsValue.decode)))
