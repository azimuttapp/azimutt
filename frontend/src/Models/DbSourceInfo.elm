module Models.DbSourceInfo exposing (DbSourceInfo, fromSource, fromSourceInfo, zero)

import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Time as Time
import Models.Project.DatabaseUrlStorage as DatabaseUrlStorage exposing (DatabaseUrlStorage)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.SourceName exposing (SourceName)
import Models.SourceInfo exposing (SourceInfo)
import Time



-- similar to SourceInfo but specialized for database sources (with url & kind easily accessible ^^)


type alias DbSourceInfo =
    { id : SourceId
    , name : SourceName
    , db : { kind : DatabaseKind, url : DatabaseUrl, storage : DatabaseUrlStorage }
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


zero : DbSourceInfo
zero =
    { id = SourceId.zero
    , name = "zero"
    , db = { kind = DatabaseKind.PostgreSQL, url = "postgres://localhost/zero", storage = DatabaseUrlStorage.Browser }
    , createdAt = Time.zero
    , updatedAt = Time.zero
    }


fromSource : Source -> Maybe DbSourceInfo
fromSource source =
    case source.kind of
        DatabaseConnection db ->
            db.url
                |> Maybe.map
                    (\url ->
                        { id = source.id
                        , name = source.name
                        , db = { kind = db.kind, url = url, storage = db.storage }
                        , createdAt = source.createdAt
                        , updatedAt = source.updatedAt
                        }
                    )

        _ ->
            Nothing


fromSourceInfo : SourceInfo -> Maybe DbSourceInfo
fromSourceInfo source =
    case source.kind of
        DatabaseConnection db ->
            db.url
                |> Maybe.map
                    (\url ->
                        { id = source.id
                        , name = source.name
                        , db = { kind = db.kind, url = url, storage = db.storage }
                        , createdAt = source.createdAt
                        , updatedAt = source.updatedAt
                        }
                    )

        _ ->
            Nothing
