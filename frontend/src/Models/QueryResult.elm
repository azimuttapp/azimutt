module Models.QueryResult exposing (QueryResult, QueryResultColumn, QueryResultColumnTarget, QueryResultRow, QueryResultSuccess, buildColumnTargets, decode, encodeQueryResultRow)

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Dict as Dict
import Libs.Json.Decode as Decode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel exposing (Nel)
import Libs.Result as Result
import Libs.Time as Time
import Models.DbColumnRef as DbColumnRef exposing (DbColumnRef)
import Models.DbSourceInfoWithUrl exposing (DbSourceInfoWithUrl)
import Models.DbValue as DbValue exposing (DbValue)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.TableId as TableId exposing (TableId)
import Models.SqlQuery as SqlQuery exposing (SqlQueryOrigin)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Organization_.Project_.Models.ErdOrigin as ErdOrigin
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import Time


type alias QueryResult =
    { context : String
    , source : SourceId
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
    { path : ColumnPath, pathStr : ColumnPathStr, schemaRef : Maybe ColumnRef, dataRef : Maybe { ref : DbColumnRef, kind : ColumnType } }


buildColumnTargets : { s | tables : Dict TableId ErdTable, relations : List ErdRelation } -> DbSourceInfoWithUrl -> List QueryResultColumn -> List QueryResultColumnTarget
buildColumnTargets erd sourceInfo columns =
    let
        relations : Dict TableId (List ErdRelation)
        relations =
            erd.relations |> List.groupBy (.src >> .table)
    in
    columns |> List.map (\c -> { path = c.path, pathStr = c.pathStr, schemaRef = c.ref, dataRef = c.ref |> Maybe.andThen (targetColumn erd.tables relations sourceInfo) })


targetColumn : Dict TableId ErdTable -> Dict TableId (List ErdRelation) -> DbSourceInfoWithUrl -> ColumnRef -> Maybe { ref : DbColumnRef, kind : ColumnType }
targetColumn tables relations sourceInfo ref =
    let
        pkRef : Maybe DbColumnRef
        pkRef =
            (tables |> TableId.dictGetI ref.table)
                |> Maybe.orElse
                    (if TableId.schema ref.table == "" then
                        -- if no schema, let's match a table only by name within the source
                        ref.table |> TableId.name |> String.toLower |> (\lowerName -> tables |> Dict.find (\k t -> ((k |> TableId.name |> String.toLower) == lowerName) && (t.origins |> List.memberBy .id sourceInfo.id)))

                     else
                        Nothing
                    )
                |> Maybe.andThen
                    (\t ->
                        t.primaryKey
                            |> Maybe.filter (\pk -> pk.columns.tail == [] && ColumnPath.eqI pk.columns.head ref.column)
                            |> Maybe.map (\pk -> DbColumnRef sourceInfo.id t.id pk.columns.head)
                    )

        fkRef : Maybe DbColumnRef
        fkRef =
            -- fk can be from any source
            (relations |> TableId.dictGetI ref.table |> Maybe.withDefault [] |> List.find (\r -> ColumnPath.eqI r.src.column ref.column))
                |> Maybe.orElse
                    (if TableId.schema ref.table == "" then
                        -- if no schema, let's match a relation within the source only using the table name
                        ref.table |> TableId.name |> String.toLower |> (\lowerName -> relations |> Dict.findMap (\k rels -> ((k |> TableId.name |> String.toLower) == lowerName) |> Maybe.fromBool |> Maybe.andThen (\_ -> rels |> List.find (\r -> ColumnPath.eqI r.src.column ref.column && (r.origins |> List.memberBy .id sourceInfo.id)))))

                     else
                        Nothing
                    )
                |> Maybe.map
                    (\r ->
                        r.ref
                            |> DbColumnRef.from
                                ((tables |> TableId.dictGetI r.ref.table |> Maybe.andThen (ErdTable.getColumnI r.ref.column))
                                    |> Maybe.mapOrElse .origins []
                                    |> ErdOrigin.query sourceInfo.id
                                )
                    )
    in
    pkRef |> Maybe.orElse fkRef |> Maybe.andThen (\targetRef -> tables |> Dict.get targetRef.table |> Maybe.andThen (ErdTable.getColumnI targetRef.column >> Maybe.map (\c -> { ref = targetRef, kind = c.kind })))


decode : Decode.Decoder QueryResult
decode =
    Decode.map6 QueryResult
        (Decode.field "context" Decode.string)
        (Decode.field "source" SourceId.decode)
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
