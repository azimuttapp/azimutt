module Models.DbSourceInfoWithUrl exposing (DbSourceInfoWithUrl, fromSource, fromSourceInfo, zero)

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


type alias DbSourceInfoWithUrl =
    { id : SourceId
    , name : SourceName
    , db : { kind : DatabaseKind, url : DatabaseUrl, storage : DatabaseUrlStorage }
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


zero : DbSourceInfoWithUrl
zero =
    { id = SourceId.zero
    , name = "zero"
    , db = { kind = DatabaseKind.default, url = "postgres://localhost/zero", storage = DatabaseUrlStorage.default }
    , createdAt = Time.zero
    , updatedAt = Time.zero
    }


fromSource : Source -> Result String DbSourceInfoWithUrl
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
                |> Result.fromMaybe ("missing url in " ++ source.name ++ " source")

        _ ->
            Err (source.name ++ " source is not a database")


fromSourceInfo : SourceInfo -> Result String DbSourceInfoWithUrl
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
                |> Result.fromMaybe ("missing url in " ++ source.name ++ " source")

        _ ->
            Err (source.name ++ " source is not a database")
