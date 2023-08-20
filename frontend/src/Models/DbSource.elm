module Models.DbSource exposing (DbSource, fromSource, toInfo, zero)

import Dict exposing (Dict)
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.Models.DatabaseUrl exposing (DatabaseUrl)
import Libs.Time as Time
import Models.DbSourceInfo exposing (DbSourceInfo)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.Relation exposing (Relation)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind as SourceKind
import Models.Project.SourceName exposing (SourceName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Time



-- similar to Source but specialized for database sources (with url & kind easily accessible ^^)


type alias DbSource =
    { id : SourceId
    , name : SourceName
    , db : { url : DatabaseUrl, kind : DatabaseKind }
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
    , db = { url = "postgres://localhost/zero", kind = DatabaseKind.PostgreSQL }
    , tables = Dict.empty
    , relations = []
    , types = Dict.empty
    , createdAt = Time.zero
    , updatedAt = Time.zero
    }


fromSource : Source -> Maybe DbSource
fromSource source =
    source.kind
        |> SourceKind.databaseUrl
        |> Maybe.map
            (\url ->
                { id = source.id
                , name = source.name
                , db = { url = url, kind = DatabaseKind.fromUrl url }
                , tables = source.tables
                , relations = source.relations
                , types = source.types
                , createdAt = source.createdAt
                , updatedAt = source.updatedAt
                }
            )


toInfo : DbSource -> DbSourceInfo
toInfo source =
    { id = source.id
    , name = source.name
    , db = source.db
    , createdAt = source.createdAt
    , updatedAt = source.updatedAt
    }
