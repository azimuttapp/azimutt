module Libs.Models.DatabaseKind exposing (DatabaseKind(..), fromUrl)

import Libs.Models.DatabaseUrl exposing (DatabaseUrl)



-- similar to libs/database-types/src/url.ts


type DatabaseKind
    = MongoDB
    | Couchbase
    | PostgreSQL
    | Other


fromUrl : DatabaseUrl -> DatabaseKind
fromUrl url =
    if url |> String.contains "mongodb" then
        MongoDB

    else if url |> String.contains "couchbase" then
        Couchbase

    else if url |> String.contains "postgre" then
        PostgreSQL

    else
        Other
