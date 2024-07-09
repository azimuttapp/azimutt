module Models.DbSource exposing (DbSource, fromSource, toInfo, toSource, zero)

import Array
import Dict exposing (Dict)
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Time as Time
import Models.DbSourceInfo exposing (DbSourceInfo)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.DatabaseUrlStorage as DatabaseUrlStorage exposing (DatabaseUrlStorage)
import Models.Project.Relation exposing (Relation)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.SourceName exposing (SourceName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Time



-- similar to Source but specialized for database sources (with url & kind easily accessible ^^)


type alias DbSource =
    { id : SourceId
    , name : SourceName
    , db : { kind : DatabaseKind, url : DatabaseUrl, storage : DatabaseUrlStorage }
    , tables : Dict TableId Table
    , relations : List Relation
    , types : Dict CustomTypeId CustomType
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


zero : DbSource
zero =
    { id = SourceId.zero
    , name = "zero"
    , db = { kind = DatabaseKind.PostgreSQL, url = "postgres://localhost/zero", storage = DatabaseUrlStorage.Browser }
    , tables = Dict.empty
    , relations = []
    , types = Dict.empty
    , createdAt = Time.zero
    , updatedAt = Time.zero
    }


fromSource : Source -> Maybe DbSource
fromSource source =
    case source.kind of
        DatabaseConnection kind (Just url) storage ->
            Just
                { id = source.id
                , name = source.name
                , db = { kind = kind, url = url, storage = storage }
                , tables = source.tables
                , relations = source.relations
                , types = source.types
                , createdAt = source.createdAt
                , updatedAt = source.updatedAt
                }

        _ ->
            Nothing


toSource : DbSource -> Source
toSource source =
    { id = source.id
    , name = source.name
    , kind = DatabaseConnection source.db.kind (Just source.db.url) source.db.storage
    , content = Array.empty
    , tables = source.tables
    , relations = source.relations
    , types = source.types
    , enabled = True
    , fromSample = Nothing
    , createdAt = source.createdAt
    , updatedAt = source.updatedAt
    }


toInfo : DbSource -> DbSourceInfo
toInfo source =
    { id = source.id
    , name = source.name
    , db = source.db
    , createdAt = source.createdAt
    , updatedAt = source.updatedAt
    }
