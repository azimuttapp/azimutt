module Models.QueryResult exposing (QueryResult, QueryResultColumn, QueryResultColumnTarget, QueryResultRow, QueryResultSuccess, buildColumnTargets, decode, encodeQueryResultRow)

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel exposing (Nel)
import Libs.Result as Result
import Libs.Time as Time
import Models.DbValue as DbValue exposing (DbValue)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.SqlQuery as SqlQuery exposing (SqlQueryOrigin)
import Time


type alias QueryResult =
    { context : String
    , query : SqlQueryOrigin
    , result : Result String QueryResultSuccess
    , started : Time.Posix
    , finished : Time.Posix
    }


type alias QueryResultSuccess =
    { columns : List QueryResultColumn
    , rows : List QueryResultRow
    }


type alias QueryResultColumn =
    { path : ColumnPath, pathStr : ColumnPathStr, ref : Maybe ColumnRef }


type alias QueryResultRow =
    Dict ColumnPathStr DbValue


type alias QueryResultColumnTarget =
    { path : ColumnPath, pathStr : ColumnPathStr, ref : Maybe ColumnRef, fk : Maybe { ref : ColumnRef, kind : ColumnType } }


buildColumnTargets : Maybe { s | tables : Dict TableId Table, relations : List Relation } -> List QueryResultColumn -> List QueryResultColumnTarget
buildColumnTargets source columns =
    let
        tables : Dict TableId Table
        tables =
            source |> Maybe.mapOrElse .tables Dict.empty

        relations : Dict TableId (List Relation)
        relations =
            source |> Maybe.mapOrElse (.relations >> List.groupBy (.src >> .table)) Dict.empty
    in
    columns |> List.map (\c -> { path = c.path, pathStr = c.pathStr, ref = c.ref, fk = c.ref |> Maybe.andThen (targetColumn tables relations) })


targetColumn : Dict TableId Table -> Dict TableId (List Relation) -> ColumnRef -> Maybe { ref : ColumnRef, kind : ColumnType }
targetColumn tables relations ref =
    let
        -- FIXME: relations without fk don't get the link :/ Should use relations from any source? Same for primary key?
        target : Maybe ColumnRef
        target =
            (tables |> TableId.dictGetI ref.table)
                |> Maybe.andThen (\t -> t.primaryKey |> Maybe.filter (\pk -> pk.columns.tail == [] && ColumnPath.eqI pk.columns.head ref.column) |> Maybe.map (\pk -> { table = t.id, column = pk.columns.head }))
                |> Maybe.orElse (relations |> TableId.dictGetI ref.table |> Maybe.withDefault [] |> List.find (\r -> ColumnPath.eqI r.src.column ref.column) |> Maybe.map .ref)
    in
    target |> Maybe.andThen (\r -> tables |> Dict.get r.table |> Maybe.andThen (\t -> t |> Table.getColumnI r.column) |> Maybe.map (\c -> { ref = r, kind = c.kind }))


decode : Decode.Decoder QueryResult
decode =
    Decode.map5 QueryResult
        (Decode.field "context" Decode.string)
        (Decode.field "query" SqlQuery.decodeOrigin)
        (Decode.field "result" (Result.decode Decode.string decodeSuccess))
        (Decode.field "started" Time.decode)
        (Decode.field "finished" Time.decode)


decodeSuccess : Decode.Decoder QueryResultSuccess
decodeSuccess =
    Decode.map2 QueryResultSuccess
        (Decode.field "columns" (Decode.list decodeColumn))
        (Decode.field "rows" (Decode.list decodeQueryResultRow))


decodeColumn : Decode.Decoder QueryResultColumn
decodeColumn =
    -- /!\ the column name is parsed as a path, and so we change the attribute name
    Decode.map3 QueryResultColumn
        (Decode.field "name" ColumnPath.decode)
        (Decode.field "name" ColumnPath.decodeStr)
        (Decode.maybeField "ref" ColumnRef.decode)


decodeQueryResultRow : Decode.Decoder QueryResultRow
decodeQueryResultRow =
    Decode.dict DbValue.decode


encodeQueryResultRow : QueryResultRow -> Value
encodeQueryResultRow value =
    value |> Encode.dict identity DbValue.encode
