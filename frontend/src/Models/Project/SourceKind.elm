module Models.Project.SourceKind exposing (SourceKind(..), SourceKindDatabase, SourceKindFileLocal, SourceKindFileRemote, database, databaseKind, databaseUrl, databaseUrlStorage, decode, encode, isDatabase, isUser, same, setDatabaseUrl, setDatabaseUrlStorage, toString)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Maybe as Maybe
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.Models.DatabaseUrl as DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.FileName as FileName exposing (FileName)
import Libs.Models.FileSize as FileSize exposing (FileSize)
import Libs.Models.FileUpdatedAt as FileUpdatedAt exposing (FileUpdatedAt)
import Libs.Models.FileUrl as FileUrl exposing (FileUrl)
import Models.Project.DatabaseUrlStorage as DatabaseUrlStorage exposing (DatabaseUrlStorage)



-- TODO: make source more flexible: connector vs parser
--   - connector:
--     - storage: Couchbase, MongoDB, MySQL, Oracle, PostgreSQL, SQLServer, SQLite
--   - parser:
--     - format: SQL, Prisma, Json, AML
--     - location: Local, Remote, Editor
-- also, fetch local file with gateway?


type SourceKind
    = DatabaseConnection SourceKindDatabase
    | SqlLocalFile SourceKindFileLocal
    | SqlRemoteFile SourceKindFileRemote
    | PrismaLocalFile SourceKindFileLocal
    | PrismaRemoteFile SourceKindFileRemote
    | JsonLocalFile SourceKindFileLocal
    | JsonRemoteFile SourceKindFileRemote
    | AmlEditor


type alias SourceKindDatabase =
    { kind : DatabaseKind, url : Maybe DatabaseUrl, storage : DatabaseUrlStorage }


type alias SourceKindFileLocal =
    { name : FileName, size : FileSize, modified : FileUpdatedAt }


type alias SourceKindFileRemote =
    { url : FileUrl, size : FileSize }


isUser : SourceKind -> Bool
isUser kind =
    case kind of
        AmlEditor ->
            True

        _ ->
            False


isDatabase : SourceKind -> Bool
isDatabase kind =
    case kind of
        DatabaseConnection _ ->
            True

        _ ->
            False


database : SourceKind -> Maybe SourceKindDatabase
database kind =
    case kind of
        DatabaseConnection db ->
            Just db

        _ ->
            Nothing


databaseKind : SourceKind -> Maybe DatabaseKind
databaseKind kind =
    case kind of
        DatabaseConnection db ->
            Just db.kind

        _ ->
            Nothing


databaseUrl : SourceKind -> Maybe DatabaseUrl
databaseUrl kind =
    case kind of
        DatabaseConnection db ->
            db.url

        _ ->
            Nothing


setDatabaseUrl : Maybe DatabaseUrl -> SourceKind -> SourceKind
setDatabaseUrl newUrl kind =
    case kind of
        DatabaseConnection db ->
            if db.url /= newUrl then
                DatabaseConnection { db | url = newUrl }

            else
                kind

        _ ->
            kind


databaseUrlStorage : SourceKind -> Maybe DatabaseUrlStorage
databaseUrlStorage kind =
    case kind of
        DatabaseConnection db ->
            Just db.storage

        _ ->
            Nothing


setDatabaseUrlStorage : DatabaseUrlStorage -> SourceKind -> SourceKind
setDatabaseUrlStorage newStorage kind =
    case kind of
        DatabaseConnection db ->
            if db.storage /= newStorage then
                DatabaseConnection { db | storage = newStorage }

            else
                kind

        _ ->
            kind


same : SourceKind -> SourceKind -> Bool
same k2 k1 =
    case ( k1, k2 ) of
        ( DatabaseConnection _, DatabaseConnection _ ) ->
            True

        ( SqlLocalFile _, SqlLocalFile _ ) ->
            True

        ( SqlRemoteFile _, SqlRemoteFile _ ) ->
            True

        ( PrismaLocalFile _, PrismaLocalFile _ ) ->
            True

        ( PrismaRemoteFile _, PrismaRemoteFile _ ) ->
            True

        ( JsonLocalFile _, JsonLocalFile _ ) ->
            True

        ( JsonRemoteFile _, JsonRemoteFile _ ) ->
            True

        ( AmlEditor, AmlEditor ) ->
            True

        _ ->
            False


toString : SourceKind -> String
toString value =
    case value of
        DatabaseConnection _ ->
            "DatabaseConnection"

        SqlLocalFile _ ->
            "SqlLocalFile"

        SqlRemoteFile _ ->
            "SqlRemoteFile"

        PrismaLocalFile _ ->
            "PrismaLocalFile"

        PrismaRemoteFile _ ->
            "PrismaRemoteFile"

        JsonLocalFile _ ->
            "JsonLocalFile"

        JsonRemoteFile _ ->
            "JsonRemoteFile"

        AmlEditor ->
            "AmlEditor"


encode : SourceKind -> Value
encode value =
    case value of
        DatabaseConnection db ->
            encodeDatabase "DatabaseConnection" db

        SqlLocalFile file ->
            encodeLocal "SqlLocalFile" file

        SqlRemoteFile file ->
            encodeRemote "SqlRemoteFile" file

        PrismaLocalFile file ->
            encodeLocal "PrismaLocalFile" file

        PrismaRemoteFile file ->
            encodeRemote "PrismaRemoteFile" file

        JsonLocalFile file ->
            encodeLocal "JsonLocalFile" file

        JsonRemoteFile file ->
            encodeRemote "JsonRemoteFile" file

        AmlEditor ->
            Encode.notNullObject [ ( "kind", "AmlEditor" |> Encode.string ) ]


decode : Decode.Decoder SourceKind
decode =
    Decode.matchOn "kind"
        (\kind ->
            case kind of
                "DatabaseConnection" ->
                    decodeDatabase

                "SqlLocalFile" ->
                    decodeLocalFile |> Decode.map SqlLocalFile

                "SqlRemoteFile" ->
                    decodeRemoteFile |> Decode.map SqlRemoteFile

                "PrismaLocalFile" ->
                    decodeLocalFile |> Decode.map PrismaLocalFile

                "PrismaRemoteFile" ->
                    decodeRemoteFile |> Decode.map PrismaRemoteFile

                "JsonLocalFile" ->
                    decodeLocalFile |> Decode.map JsonLocalFile

                "JsonRemoteFile" ->
                    decodeRemoteFile |> Decode.map JsonRemoteFile

                "AmlEditor" ->
                    Decode.succeed AmlEditor

                -- legacy names:
                "LocalFile" ->
                    decodeLocalFile |> Decode.map SqlLocalFile

                "RemoteFile" ->
                    decodeRemoteFile |> Decode.map SqlRemoteFile

                "UserDefined" ->
                    Decode.succeed AmlEditor

                other ->
                    Decode.fail ("Not supported kind of SourceKind '" ++ other ++ "'")
        )


encodeLocal : String -> SourceKindFileLocal -> Value
encodeLocal kind file =
    Encode.notNullObject
        [ ( "kind", kind |> Encode.string )
        , ( "name", file.name |> FileName.encode )
        , ( "size", file.size |> FileSize.encode )
        , ( "modified", file.modified |> FileUpdatedAt.encode )
        ]


decodeLocalFile : Decode.Decoder SourceKindFileLocal
decodeLocalFile =
    Decode.map3 (\name size modified -> { name = name, size = size, modified = modified })
        (Decode.field "name" FileName.decode)
        (Decode.field "size" FileSize.decode)
        (Decode.field "modified" FileUpdatedAt.decode)


encodeRemote : String -> SourceKindFileRemote -> Value
encodeRemote kind file =
    Encode.notNullObject
        [ ( "kind", kind |> Encode.string )
        , ( "url", file.url |> FileUrl.encode )
        , ( "size", file.size |> FileSize.encode )
        ]


decodeRemoteFile : Decode.Decoder SourceKindFileRemote
decodeRemoteFile =
    Decode.map2 (\url size -> { url = url, size = size })
        (Decode.field "url" FileUrl.decode)
        (Decode.field "size" FileSize.decode)


encodeDatabase : String -> SourceKindDatabase -> Value
encodeDatabase kind db =
    Encode.notNullObject
        [ ( "kind", kind |> Encode.string )
        , ( "engine", db.kind |> DatabaseKind.encode )
        , ( "url", db.url |> Encode.maybe DatabaseUrl.encode )
        , ( "storage", db.storage |> DatabaseUrlStorage.encode )
        ]


decodeDatabase : Decode.Decoder SourceKind
decodeDatabase =
    Decode.oneOf
        [ Decode.map3 (\kind url storage -> DatabaseConnection { kind = kind, url = url, storage = storage })
            (Decode.field "engine" DatabaseKind.decode)
            (Decode.maybeField "url" DatabaseUrl.decode)
            (Decode.field "storage" DatabaseUrlStorage.decode)
        , Decode.map (\( kind, url ) -> DatabaseConnection { kind = kind, url = Just url, storage = DatabaseUrlStorage.Project })
            (Decode.field "url" DatabaseUrl.decode
                |> Decode.andThen (\url -> url |> DatabaseKind.fromUrl |> Maybe.tuple url |> Decode.fromMaybe "Unknown DatabaseKind from url")
            )
        ]
