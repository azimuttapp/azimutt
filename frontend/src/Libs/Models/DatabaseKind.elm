module Libs.Models.DatabaseKind exposing (DatabaseKind(..), all, decode, encode, fromUrl, show, toString)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)


type DatabaseKind
    = BigQuery
    | Couchbase
    | MariaDB
    | MongoDB
    | MySQL
    | PostgreSQL
    | Snowflake
    | SQLServer


all : List DatabaseKind
all =
    [ BigQuery, Couchbase, MariaDB, MongoDB, MySQL, PostgreSQL, Snowflake, SQLServer ]


fromUrl : DatabaseUrl -> Maybe DatabaseKind
fromUrl url =
    if url |> String.contains "bigquery" then
        Just BigQuery

    else if url |> String.contains "couchbase" then
        Just Couchbase

    else if url |> String.contains "mariadb" then
        Just MariaDB

    else if url |> String.contains "mongodb" then
        Just MongoDB

    else if url |> String.contains "mysql" then
        Just MySQL

    else if url |> String.contains "postgre" then
        Just PostgreSQL

    else if url |> String.contains "snowflake" then
        Just Snowflake

    else if (url |> String.contains "sqlserver") || (url |> String.toLower |> String.contains "user id=") then
        Just SQLServer

    else
        Nothing


show : DatabaseKind -> String
show kind =
    case kind of
        BigQuery ->
            "BigQuery"

        Couchbase ->
            "Couchbase"

        MariaDB ->
            "MariaDB"

        MongoDB ->
            "MongoDB"

        MySQL ->
            "MySQL"

        PostgreSQL ->
            "PostgreSQL"

        Snowflake ->
            "Snowflake"

        SQLServer ->
            "SQLServer"


toString : DatabaseKind -> String
toString kind =
    -- MUST stay sync with to libs/models/src/database.ts#DatabaseKind
    case kind of
        BigQuery ->
            "bigquery"

        Couchbase ->
            "couchbase"

        MariaDB ->
            "mariadb"

        MongoDB ->
            "mongodb"

        MySQL ->
            "mysql"

        PostgreSQL ->
            "postgres"

        Snowflake ->
            "snowflake"

        SQLServer ->
            "sqlserver"


fromString : String -> Maybe DatabaseKind
fromString kind =
    case kind of
        "bigquery" ->
            Just BigQuery

        "couchbase" ->
            Just Couchbase

        "mariadb" ->
            Just MariaDB

        "mongodb" ->
            Just MongoDB

        "mysql" ->
            Just MySQL

        "postgres" ->
            Just PostgreSQL

        "snowflake" ->
            Just Snowflake

        "sqlserver" ->
            Just SQLServer

        _ ->
            Nothing


encode : DatabaseKind -> Value
encode value =
    value |> toString |> Encode.string


decode : Decoder DatabaseKind
decode =
    Decode.string |> Decode.andThen (\v -> v |> fromString |> Maybe.map Decode.succeed |> Maybe.withDefault (Decode.fail ("Unknown DatabaseKind:" ++ v)))
