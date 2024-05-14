module Models.SqlQuery exposing (SqlQuery, SqlQueryOrigin, decodeOrigin, encodeOrigin)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as Encode
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)


type alias SqlQuery =
    -- a single and complete SQL query
    String


type alias SqlQueryOrigin =
    -- to know from where the SQL query comes from
    -- TODO: add optional name & description (store prompt in description)
    { sql : SqlQuery, origin : String, db : DatabaseKind }


encodeOrigin : SqlQueryOrigin -> Value
encodeOrigin value =
    Encode.notNullObject
        [ ( "sql", value.sql |> Encode.string )
        , ( "origin", value.origin |> Encode.string )
        , ( "db", value.db |> DatabaseKind.encode )
        ]


decodeOrigin : Decoder SqlQueryOrigin
decodeOrigin =
    Decode.map3 SqlQueryOrigin
        (Decode.field "sql" Decode.string)
        (Decode.field "origin" Decode.string)
        (Decode.field "db" DatabaseKind.decode)
