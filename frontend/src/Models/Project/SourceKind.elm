module Models.Project.SourceKind exposing (SourceKind(..), databaseKind, databaseUrl, databaseUrlStorage, decode, encode, isDatabase, isUser, same, setDatabaseUrlStorage, toString)

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
import Libs.Tuple as Tuple
import Libs.Tuple3 as Tuple3
import Models.Project.DatabaseUrlStorage as DatabaseUrlStorage exposing (DatabaseUrlStorage)



-- TODO: make source more flexible: connector vs parser
--   - connector:
--     - storage: Couchbase, MongoDB, MySQL, Oracle, PostgreSQL, SQLServer, SQLite
--   - parser:
--     - format: SQL, Prisma, Json, AML
--     - location: Local, Remote, Editor
-- also, fetch local file with gateway?


type SourceKind
    = DatabaseConnection DatabaseKind (Maybe DatabaseUrl) DatabaseUrlStorage
    | SqlLocalFile FileName FileSize FileUpdatedAt
    | SqlRemoteFile FileUrl FileSize
    | PrismaLocalFile FileName FileSize FileUpdatedAt
    | PrismaRemoteFile FileUrl FileSize
    | JsonLocalFile FileName FileSize FileUpdatedAt
    | JsonRemoteFile FileUrl FileSize
    | AmlEditor


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
        DatabaseConnection _ _ _ ->
            True

        _ ->
            False


databaseKind : SourceKind -> Maybe DatabaseKind
databaseKind kind =
    case kind of
        DatabaseConnection engine _ _ ->
            Just engine

        _ ->
            Nothing


databaseUrl : SourceKind -> Maybe DatabaseUrl
databaseUrl kind =
    case kind of
        DatabaseConnection _ url _ ->
            url

        _ ->
            Nothing


databaseUrlStorage : SourceKind -> Maybe DatabaseUrlStorage
databaseUrlStorage kind =
    case kind of
        DatabaseConnection _ _ storage ->
            Just storage

        _ ->
            Nothing


setDatabaseUrlStorage : DatabaseUrlStorage -> SourceKind -> SourceKind
setDatabaseUrlStorage newStorage kind =
    case kind of
        DatabaseConnection engine url storage ->
            if storage /= newStorage then
                DatabaseConnection engine url newStorage

            else
                kind

        _ ->
            kind


same : SourceKind -> SourceKind -> Bool
same k2 k1 =
    case ( k1, k2 ) of
        ( DatabaseConnection _ _ _, DatabaseConnection _ _ _ ) ->
            True

        ( SqlLocalFile _ _ _, SqlLocalFile _ _ _ ) ->
            True

        ( SqlRemoteFile _ _, SqlRemoteFile _ _ ) ->
            True

        ( PrismaLocalFile _ _ _, PrismaLocalFile _ _ _ ) ->
            True

        ( PrismaRemoteFile _ _, PrismaRemoteFile _ _ ) ->
            True

        ( JsonLocalFile _ _ _, JsonLocalFile _ _ _ ) ->
            True

        ( JsonRemoteFile _ _, JsonRemoteFile _ _ ) ->
            True

        ( AmlEditor, AmlEditor ) ->
            True

        _ ->
            False


toString : SourceKind -> String
toString value =
    case value of
        DatabaseConnection _ _ _ ->
            "DatabaseConnection"

        SqlLocalFile _ _ _ ->
            "SqlLocalFile"

        SqlRemoteFile _ _ ->
            "SqlRemoteFile"

        PrismaLocalFile _ _ _ ->
            "PrismaLocalFile"

        PrismaRemoteFile _ _ ->
            "PrismaRemoteFile"

        JsonLocalFile _ _ _ ->
            "JsonLocalFile"

        JsonRemoteFile _ _ ->
            "JsonRemoteFile"

        AmlEditor ->
            "AmlEditor"


encode : SourceKind -> Value
encode value =
    case value of
        DatabaseConnection engine url storage ->
            encodeDatabase "DatabaseConnection" engine url storage

        SqlLocalFile name size modified ->
            encodeLocal "SqlLocalFile" name size modified

        SqlRemoteFile name size ->
            encodeRemote "SqlRemoteFile" name size

        PrismaLocalFile name size modified ->
            encodeLocal "PrismaLocalFile" name size modified

        PrismaRemoteFile name size ->
            encodeRemote "PrismaRemoteFile" name size

        JsonLocalFile name size modified ->
            encodeLocal "JsonLocalFile" name size modified

        JsonRemoteFile name size ->
            encodeRemote "JsonRemoteFile" name size

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
                    decodeLocalFile |> Decode.map (Tuple3.apply SqlLocalFile)

                "SqlRemoteFile" ->
                    decodeRemoteFile |> Decode.map (Tuple.apply SqlRemoteFile)

                "PrismaLocalFile" ->
                    decodeLocalFile |> Decode.map (Tuple3.apply PrismaLocalFile)

                "PrismaRemoteFile" ->
                    decodeRemoteFile |> Decode.map (Tuple.apply PrismaRemoteFile)

                "JsonLocalFile" ->
                    decodeLocalFile |> Decode.map (Tuple3.apply JsonLocalFile)

                "JsonRemoteFile" ->
                    decodeRemoteFile |> Decode.map (Tuple.apply JsonRemoteFile)

                "AmlEditor" ->
                    Decode.succeed AmlEditor

                -- legacy names:
                "LocalFile" ->
                    decodeLocalFile |> Decode.map (Tuple3.apply SqlLocalFile)

                "RemoteFile" ->
                    decodeRemoteFile |> Decode.map (Tuple.apply SqlRemoteFile)

                "UserDefined" ->
                    Decode.succeed AmlEditor

                other ->
                    Decode.fail ("Not supported kind of SourceKind '" ++ other ++ "'")
        )


encodeLocal : String -> FileName -> FileSize -> FileUpdatedAt -> Value
encodeLocal kind name size modified =
    Encode.notNullObject
        [ ( "kind", kind |> Encode.string )
        , ( "name", name |> FileName.encode )
        , ( "size", size |> FileSize.encode )
        , ( "modified", modified |> FileUpdatedAt.encode )
        ]


decodeLocalFile : Decode.Decoder ( FileName, FileSize, FileUpdatedAt )
decodeLocalFile =
    Decode.map3 Tuple3.new
        (Decode.field "name" FileName.decode)
        (Decode.field "size" FileSize.decode)
        (Decode.field "modified" FileUpdatedAt.decode)


encodeRemote : String -> FileUrl -> FileSize -> Value
encodeRemote kind name size =
    Encode.notNullObject
        [ ( "kind", kind |> Encode.string )
        , ( "url", name |> FileUrl.encode )
        , ( "size", size |> FileSize.encode )
        ]


decodeRemoteFile : Decode.Decoder ( FileUrl, FileSize )
decodeRemoteFile =
    Decode.map2 Tuple.new
        (Decode.field "url" FileUrl.decode)
        (Decode.field "size" FileSize.decode)


encodeDatabase : String -> DatabaseKind -> Maybe DatabaseUrl -> DatabaseUrlStorage -> Value
encodeDatabase kind engine url storage =
    Encode.notNullObject
        [ ( "kind", kind |> Encode.string )
        , ( "engine", engine |> DatabaseKind.encode )
        , ( "url", url |> Encode.maybe DatabaseUrl.encode )
        , ( "storage", storage |> DatabaseUrlStorage.encode )
        ]


decodeDatabase : Decode.Decoder SourceKind
decodeDatabase =
    Decode.oneOf
        [ Decode.map3 DatabaseConnection
            (Decode.field "engine" DatabaseKind.decode)
            (Decode.maybeField "url" DatabaseUrl.decode)
            (Decode.field "storage" DatabaseUrlStorage.decode)
        , Decode.map (\( engine, url ) -> DatabaseConnection engine (Just url) DatabaseUrlStorage.Project)
            (Decode.field "url" DatabaseUrl.decode
                |> Decode.andThen (\url -> url |> DatabaseKind.fromUrl |> Maybe.tuple url |> Decode.fromMaybe "Unknown DatabaseKind from url")
            )
        ]
