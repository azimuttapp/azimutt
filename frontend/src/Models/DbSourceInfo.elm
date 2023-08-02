module Models.DbSourceInfo exposing (DbSourceInfo, fromSource, fromSourceInfo, zero)

import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Time as Time
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind as SourceKind
import Models.Project.SourceName exposing (SourceName)
import Models.SourceInfo exposing (SourceInfo)
import Time



-- similar to SourceInfo but specialized for database sources (with url & kind easily accessible ^^)


type alias DbSourceInfo =
    { id : SourceId
    , name : SourceName
    , db : { url : DatabaseUrl, kind : DatabaseKind }
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


zero : DbSourceInfo
zero =
    { id = SourceId.zero
    , name = "default source"
    , db = { url = "postgres://localhost/default", kind = DatabaseKind.PostgreSQL }
    , createdAt = Time.zero
    , updatedAt = Time.zero
    }


fromSource : Source -> Maybe DbSourceInfo
fromSource source =
    source.kind
        |> SourceKind.databaseUrl
        |> Maybe.map
            (\url ->
                { id = source.id
                , name = source.name
                , db = { url = url, kind = DatabaseKind.fromUrl url }
                , createdAt = source.createdAt
                , updatedAt = source.updatedAt
                }
            )


fromSourceInfo : SourceInfo -> Maybe DbSourceInfo
fromSourceInfo source =
    source.kind
        |> SourceKind.databaseUrl
        |> Maybe.map
            (\url ->
                { id = source.id
                , name = source.name
                , db = { url = url, kind = DatabaseKind.fromUrl url }
                , createdAt = source.createdAt
                , updatedAt = source.updatedAt
                }
            )
