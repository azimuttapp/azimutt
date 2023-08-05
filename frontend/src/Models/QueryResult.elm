module Models.QueryResult exposing (QueryResult, QueryResultColumn, QueryResultColumnTarget, QueryResultRow, QueryResultSuccess, buildColumnTargets, decode)

import Dict exposing (Dict)
import Json.Decode as Decode
import Libs.Dict as Dict
import Libs.Json.Decode as Decode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel exposing (Nel)
import Libs.Result as Result
import Libs.Time as Time
import Models.DbValue as DbValue exposing (DbValue)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
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
    Dict String DbValue


type alias QueryResultColumnTarget =
    { name : String, open : Maybe { ref : ColumnRef, kind : ColumnType } }


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
    columns |> List.map (\c -> { name = c.name, open = c.ref |> Maybe.andThen (targetColumn tables relations) })


targetColumn : Dict TableId Table -> Dict TableId (List Relation) -> ColumnRef -> Maybe { ref : ColumnRef, kind : ColumnType }
targetColumn tables relations ref =
    let
        -- FIXME: relations without fk don't get the link :/ Should use relations from any source? Same for primary key?
        target : Maybe ColumnRef
        target =
            if tables |> Dict.get ref.table |> Maybe.andThen .primaryKey |> Maybe.any (\pk -> pk.columns == Nel ref.column []) then
                Just ref

            else
                relations |> Dict.getOrElse ref.table [] |> List.find (\r -> r.src == ref) |> Maybe.map .ref
    in
    target |> Maybe.andThen (\r -> tables |> Dict.get r.table |> Maybe.andThen (\t -> t |> Table.getColumn r.column) |> Maybe.map (\c -> { ref = r, kind = c.kind }))


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
        (Decode.field "rows" (Decode.list (Decode.dict DbValue.decode)))


decodeColumn : Decode.Decoder QueryResultColumn
decodeColumn =
    Decode.map2 QueryResultColumn
        (Decode.field "name" Decode.string)
        (Decode.maybeField "ref" ColumnRef.decode)
