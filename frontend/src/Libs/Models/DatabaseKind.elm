module Libs.Models.DatabaseKind exposing (DatabaseKind(..), all, decode, encode, fromUrl, toString)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)



-- similar to libs/database-types/src/url.ts


type DatabaseKind
    = Couchbase
    | MariaDB
    | MongoDB
    | MySQL
    | PostgreSQL
    | SQLServer
    | Other


all : List DatabaseKind
all =
    [ Couchbase, MariaDB, MongoDB, MySQL, PostgreSQL, SQLServer, Other ]


fromUrl : DatabaseUrl -> DatabaseKind
fromUrl url =
    if url |> String.contains "couchbase" then
        Couchbase

    else if url |> String.contains "mariadb" then
        MariaDB

    else if url |> String.contains "mongodb" then
        MongoDB

    else if url |> String.contains "mysql" then
        MySQL

    else if url |> String.contains "postgre" then
        PostgreSQL

    else if (url |> String.contains "sqlserver") || (url |> String.toLower |> String.contains "user id=") then
        SQLServer

    else
        Other


toString : DatabaseKind -> String
toString kind =
    case kind of
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

        SQLServer ->
            "SQLServer"

        Other ->
            "Other"


fromString : String -> Maybe DatabaseKind
fromString kind =
    case kind of
        "Couchbase" ->
            Just Couchbase

        "MariaDB" ->
            Just MariaDB

        "MongoDB" ->
            Just MongoDB

        "MySQL" ->
            Just MySQL

        "PostgreSQL" ->
            Just PostgreSQL

        "SQLServer" ->
            Just SQLServer

        "Other" ->
            Just Other

        _ ->
            Nothing


encode : DatabaseKind -> Value
encode value =
    value |> toString |> Encode.string


decode : Decoder DatabaseKind
decode =
    Decode.string |> Decode.andThen (\v -> v |> fromString |> Maybe.map Decode.succeed |> Maybe.withDefault (Decode.fail ("Unknown DatabaseKind:" ++ v)))
