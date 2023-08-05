module Models.Project.TableRow exposing (FailureState, Id, LoadingState, State(..), SuccessState, TableRow, TableRowValue, decode, encode, toHtmlId)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Time as Time
import Models.DbValue as DbValue exposing (DbValue)
import Models.Position as Position
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Size as Size
import Services.QueryBuilder exposing (ColumnMatch, RowQuery, decodeRowQuery, encodeRowQuery)
import Set exposing (Set)
import Time


type alias Id =
    Int


type alias TableRow =
    { id : Id
    , position : Position.Grid
    , size : Size.Canvas
    , source : SourceId
    , query : RowQuery
    , state : State
    }


type State
    = StateLoading LoadingState
    | StateFailure FailureState
    | StateSuccess SuccessState


type alias LoadingState =
    { query : String, startedAt : Time.Posix }


type alias FailureState =
    { query : String, error : String, startedAt : Time.Posix, failedAt : Time.Posix }


type alias SuccessState =
    { values : List TableRowValue
    , hidden : Set ColumnName
    , expanded : Set ColumnName
    , showHidden : Bool
    , startedAt : Time.Posix
    , loadedAt : Time.Posix
    }


type alias TableRowValue =
    { column : ColumnName, value : DbValue }


toHtmlId : TableRow -> HtmlId
toHtmlId row =
    "az-table-row-" ++ String.fromInt row.id


encode : TableRow -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> Encode.int )
        , ( "position", value.position |> Position.encodeGrid )
        , ( "size", value.size |> Size.encodeCanvas )
        , ( "source", value.source |> SourceId.encode )
        , ( "query", value.query |> encodeRowQuery )
        , ( "state", value.state |> encodeState )
        ]


decode : Decoder TableRow
decode =
    Decode.map6 TableRow
        (Decode.field "id" Decode.int)
        (Decode.field "position" Position.decodeGrid)
        (Decode.field "size" Size.decodeCanvas)
        (Decode.field "source" SourceId.decode)
        (Decode.field "query" decodeRowQuery)
        (Decode.field "state" decodeState)


encodeState : State -> Value
encodeState value =
    case value of
        StateSuccess s ->
            encodeSuccessState s

        StateFailure s ->
            encodeFailureState s

        StateLoading s ->
            encodeLoadingState s


decodeState : Decoder State
decodeState =
    Decode.oneOf
        [ decodeSuccessState |> Decode.map StateSuccess
        , decodeFailureState |> Decode.map StateFailure
        , decodeLoadingState |> Decode.map StateLoading
        ]


encodeLoadingState : LoadingState -> Value
encodeLoadingState value =
    Encode.notNullObject
        [ ( "query", value.query |> Encode.string )
        , ( "startedAt", value.startedAt |> Time.encode )
        ]


decodeLoadingState : Decoder LoadingState
decodeLoadingState =
    Decode.map2 LoadingState
        (Decode.field "query" Decode.string)
        (Decode.field "startedAt" Time.decode)


encodeFailureState : FailureState -> Value
encodeFailureState value =
    Encode.notNullObject
        [ ( "query", value.query |> Encode.string )
        , ( "error", value.error |> Encode.string )
        , ( "startedAt", value.startedAt |> Time.encode )
        , ( "failedAt", value.failedAt |> Time.encode )
        ]


decodeFailureState : Decoder FailureState
decodeFailureState =
    Decode.map4 FailureState
        (Decode.field "query" Decode.string)
        (Decode.field "error" Decode.string)
        (Decode.field "startedAt" Time.decode)
        (Decode.field "failedAt" Time.decode)


encodeSuccessState : SuccessState -> Value
encodeSuccessState value =
    Encode.notNullObject
        [ ( "values", value.values |> Encode.list encodeTableRowValue )
        , ( "hidden", value.hidden |> Encode.set ColumnName.encode )
        , ( "expanded", value.expanded |> Encode.set ColumnName.encode )
        , ( "showHidden", value.showHidden |> Encode.bool )
        , ( "startedAt", value.startedAt |> Time.encode )
        , ( "loadedAt", value.loadedAt |> Time.encode )
        ]


decodeSuccessState : Decoder SuccessState
decodeSuccessState =
    Decode.map6 SuccessState
        (Decode.field "values" (Decode.list decodeTableRowValue))
        (Decode.field "hidden" (Decode.set ColumnName.decode))
        (Decode.field "expanded" (Decode.set ColumnName.decode))
        (Decode.field "showHidden" Decode.bool)
        (Decode.field "startedAt" Time.decode)
        (Decode.field "loadedAt" Time.decode)


encodeTableRowValue : TableRowValue -> Value
encodeTableRowValue value =
    Encode.object
        [ ( "column", value.column |> ColumnName.encode )
        , ( "value", value.value |> DbValue.encode )
        ]


decodeTableRowValue : Decoder TableRowValue
decodeTableRowValue =
    Decode.map2 TableRowValue
        (Decode.field "column" ColumnName.decode)
        (Decode.field "value" DbValue.decode)
