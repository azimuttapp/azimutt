module Models.Project.TableRow exposing (FailureState, Id, LoadingState, State(..), SuccessState, TableRow, TableRowColumn, decode, encode, fromHtmlId, isHtmlId, stateSuccess, toHtmlId)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Time as Time
import Models.DbValue as DbValue exposing (DbValue)
import Models.Position as Position
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.RowPrimaryKey as RowPrimaryKey exposing (RowPrimaryKey)
import Models.Project.SourceId as SourceId exposing (SourceId, SourceIdStr)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Size as Size
import Models.SqlQuery as SqlQuery exposing (SqlQueryOrigin)
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)
import Set exposing (Set)
import Time


type alias Id =
    Int


type alias TableRow =
    { id : Id
    , positionHint : Maybe PositionHint
    , position : Position.Grid
    , size : Size.Canvas
    , source : SourceId
    , table : TableId
    , primaryKey : RowPrimaryKey
    , state : State
    , hidden : Set ColumnName
    , showHiddenColumns : Bool
    , selected : Bool
    , collapsed : Bool
    }


type State
    = StateLoading LoadingState
    | StateFailure FailureState
    | StateSuccess SuccessState


type alias LoadingState =
    { query : SqlQueryOrigin, startedAt : Time.Posix, previous : Maybe SuccessState }


type alias FailureState =
    { query : SqlQueryOrigin, error : String, startedAt : Time.Posix, failedAt : Time.Posix, previous : Maybe SuccessState }


type alias SuccessState =
    { columns : List TableRowColumn
    , startedAt : Time.Posix
    , loadedAt : Time.Posix
    }


type alias TableRowColumn =
    { path : ColumnPath, pathStr : ColumnPathStr, value : DbValue, linkedBy : Dict SourceIdStr (Dict TableId (List RowPrimaryKey)) }


stateSuccess : TableRow -> Maybe SuccessState
stateSuccess row =
    case row.state of
        StateSuccess s ->
            Just s

        _ ->
            Nothing


htmlIdPrefix : HtmlId
htmlIdPrefix =
    "az-table-row-"


isHtmlId : HtmlId -> Bool
isHtmlId id =
    id |> String.startsWith htmlIdPrefix


toHtmlId : Id -> HtmlId
toHtmlId id =
    htmlIdPrefix ++ String.fromInt id


fromHtmlId : HtmlId -> Maybe Id
fromHtmlId id =
    if isHtmlId id then
        id |> String.stripLeft htmlIdPrefix |> String.toInt

    else
        Nothing


encode : TableRow -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> Encode.int )
        , ( "position", value.position |> Position.encodeGrid )
        , ( "size", value.size |> Size.encodeCanvas )
        , ( "source", value.source |> SourceId.encode )
        , ( "table", value.table |> TableId.encode )
        , ( "primaryKey", value.primaryKey |> RowPrimaryKey.encode )
        , ( "state", value.state |> encodeState )
        , ( "hidden", value.hidden |> Encode.withDefault (Encode.set ColumnPath.encodeStr) Set.empty )
        , ( "showHiddenColumns", value.showHiddenColumns |> Encode.withDefault Encode.bool False )
        , ( "selected", value.selected |> Encode.withDefault Encode.bool False )
        , ( "collapsed", value.collapsed |> Encode.withDefault Encode.bool False )
        ]


decode : Decoder TableRow
decode =
    Decode.map12 TableRow
        (Decode.field "id" Decode.int)
        (Decode.succeed Nothing)
        (Decode.field "position" Position.decodeGrid)
        (Decode.field "size" Size.decodeCanvas)
        (Decode.field "source" SourceId.decode)
        (Decode.field "table" TableId.decode)
        (Decode.field "primaryKey" RowPrimaryKey.decode)
        (Decode.field "state" decodeState)
        (Decode.defaultField "hidden" (Decode.set ColumnPath.decodeStr) Set.empty)
        (Decode.defaultField "showHiddenColumns" Decode.bool False)
        (Decode.defaultField "selected" Decode.bool False)
        (Decode.defaultField "collapsed" Decode.bool False)


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
        [ ( "query", value.query |> SqlQuery.encodeOrigin )
        , ( "startedAt", value.startedAt |> Time.encode )
        , ( "previous", value.previous |> Encode.maybe encodeSuccessState )
        ]


decodeLoadingState : Decoder LoadingState
decodeLoadingState =
    Decode.map3 LoadingState
        (Decode.field "query" SqlQuery.decodeOrigin)
        (Decode.field "startedAt" Time.decode)
        (Decode.maybeField "previous" decodeSuccessState)


encodeFailureState : FailureState -> Value
encodeFailureState value =
    Encode.notNullObject
        [ ( "query", value.query |> SqlQuery.encodeOrigin )
        , ( "error", value.error |> Encode.string )
        , ( "startedAt", value.startedAt |> Time.encode )
        , ( "failedAt", value.failedAt |> Time.encode )
        , ( "previous", value.previous |> Encode.maybe encodeSuccessState )
        ]


decodeFailureState : Decoder FailureState
decodeFailureState =
    Decode.map5 FailureState
        (Decode.field "query" SqlQuery.decodeOrigin)
        (Decode.field "error" Decode.string)
        (Decode.field "startedAt" Time.decode)
        (Decode.field "failedAt" Time.decode)
        (Decode.maybeField "previous" decodeSuccessState)


encodeSuccessState : SuccessState -> Value
encodeSuccessState value =
    Encode.notNullObject
        [ ( "columns", value.columns |> Encode.list encodeTableRowColumn )
        , ( "startedAt", value.startedAt |> Time.encode )
        , ( "loadedAt", value.loadedAt |> Time.encode )
        ]


decodeSuccessState : Decoder SuccessState
decodeSuccessState =
    Decode.map3 SuccessState
        (Decode.field "columns" (Decode.list decodeTableRowColumn))
        (Decode.field "startedAt" Time.decode)
        (Decode.field "loadedAt" Time.decode)


encodeTableRowColumn : TableRowColumn -> Value
encodeTableRowColumn value =
    Encode.object
        -- don't use Encode.notNullObject to keep `value` key even when it's null
        [ ( "path", value.path |> ColumnPath.encode )
        , ( "value", value.value |> DbValue.encode )
        ]


decodeTableRowColumn : Decoder TableRowColumn
decodeTableRowColumn =
    Decode.map4 TableRowColumn
        (Decode.field "path" ColumnPath.decode)
        (Decode.field "path" ColumnPath.decodeStr)
        (Decode.field "value" DbValue.decode)
        (Decode.succeed Dict.empty)
