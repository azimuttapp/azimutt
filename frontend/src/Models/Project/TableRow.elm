module Models.Project.TableRow exposing (FailureState, Id, LoadingState, State(..), SuccessState, TableRow, TableRowValue, decode, encode, fromHtmlId, isHtmlId, stateSuccess, toHtmlId)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Libs.Time as Time
import Models.DbValue as DbValue exposing (DbValue)
import Models.Position as Position
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.PositionHint exposing (PositionHint)
import Services.QueryBuilder exposing (ColumnMatch, RowQuery, decodeRowQuery, encodeRowQuery)
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
    , query : RowQuery
    , state : State
    , selected : Bool
    }


type State
    = StateLoading LoadingState
    | StateFailure FailureState
    | StateSuccess SuccessState


type alias LoadingState =
    { query : String, startedAt : Time.Posix, previous : Maybe SuccessState }


type alias FailureState =
    { query : String, error : String, startedAt : Time.Posix, failedAt : Time.Posix, previous : Maybe SuccessState }


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
        , ( "query", value.query |> encodeRowQuery )
        , ( "state", value.state |> encodeState )
        , ( "selected", value.selected |> Encode.withDefault Encode.bool False )
        ]


decode : Decoder TableRow
decode =
    Decode.map8 TableRow
        (Decode.field "id" Decode.int)
        (Decode.succeed Nothing)
        (Decode.field "position" Position.decodeGrid)
        (Decode.field "size" Size.decodeCanvas)
        (Decode.field "source" SourceId.decode)
        (Decode.field "query" decodeRowQuery)
        (Decode.field "state" decodeState)
        (Decode.defaultField "selected" Decode.bool False)


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
        , ( "previous", value.previous |> Encode.maybe encodeSuccessState )
        ]


decodeLoadingState : Decoder LoadingState
decodeLoadingState =
    Decode.map3 LoadingState
        (Decode.field "query" Decode.string)
        (Decode.field "startedAt" Time.decode)
        (Decode.maybeField "previous" decodeSuccessState)


encodeFailureState : FailureState -> Value
encodeFailureState value =
    Encode.notNullObject
        [ ( "query", value.query |> Encode.string )
        , ( "error", value.error |> Encode.string )
        , ( "startedAt", value.startedAt |> Time.encode )
        , ( "failedAt", value.failedAt |> Time.encode )
        , ( "previous", value.previous |> Encode.maybe encodeSuccessState )
        ]


decodeFailureState : Decoder FailureState
decodeFailureState =
    Decode.map5 FailureState
        (Decode.field "query" Decode.string)
        (Decode.field "error" Decode.string)
        (Decode.field "startedAt" Time.decode)
        (Decode.field "failedAt" Time.decode)
        (Decode.maybeField "previous" decodeSuccessState)


encodeSuccessState : SuccessState -> Value
encodeSuccessState value =
    Encode.notNullObject
        [ ( "values", value.values |> Encode.list encodeTableRowValue )
        , ( "hidden", value.hidden |> Encode.withDefault (Encode.set ColumnName.encode) Set.empty )
        , ( "expanded", value.expanded |> Encode.withDefault (Encode.set ColumnName.encode) Set.empty )
        , ( "showHidden", value.showHidden |> Encode.withDefault Encode.bool False )
        , ( "startedAt", value.startedAt |> Time.encode )
        , ( "loadedAt", value.loadedAt |> Time.encode )
        ]


decodeSuccessState : Decoder SuccessState
decodeSuccessState =
    Decode.map6 SuccessState
        (Decode.field "values" (Decode.list decodeTableRowValue))
        (Decode.defaultField "hidden" (Decode.set ColumnName.decode) Set.empty)
        (Decode.defaultField "expanded" (Decode.set ColumnName.decode) Set.empty)
        (Decode.defaultField "showHidden" Decode.bool False)
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
