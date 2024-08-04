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
    , db : { kind : DatabaseKind, url : Maybe DatabaseUrl, storage : DatabaseUrlStorage }
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


zero : DbSourceInfo
zero =
    { id = SourceId.zero
    , name = "zero"
    , db = { kind = DatabaseKind.default, url = Just "postgres://localhost/zero", storage = DatabaseUrlStorage.default }
    , createdAt = Time.zero
    , updatedAt = Time.zero
    }


fromSource : Source -> Maybe DbSourceInfo
fromSource source =
    case source.kind of
        DatabaseConnection db ->
            { id = source.id
            , name = source.name
            , db = { kind = db.kind, url = db.url, storage = db.storage }
            , createdAt = source.createdAt
            , updatedAt = source.updatedAt
            }
                |> Just

        _ ->
            Nothing


fromSourceInfo : SourceInfo -> Maybe DbSourceInfo
fromSourceInfo source =
    case source.kind of
        DatabaseConnection db ->
            { id = source.id
            , name = source.name
            , db = { kind = db.kind, url = db.url, storage = db.storage }
            , createdAt = source.createdAt
            , updatedAt = source.updatedAt
            }
                |> Just

        _ ->
            Nothing
