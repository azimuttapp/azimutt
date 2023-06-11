module Models.Project.SourceKind exposing (SourceKind(..), decode, encode, isDatabase, isUser, path, same, toString)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Models.DatabaseUrl as DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.FileName as FileName exposing (FileName)
import Libs.Models.FileSize as FileSize exposing (FileSize)
import Libs.Models.FileUpdatedAt as FileUpdatedAt exposing (FileUpdatedAt)
import Libs.Models.FileUrl as FileUrl exposing (FileUrl)
import Libs.Tuple as Tuple
import Libs.Tuple3 as Tuple3



-- TODO: make source more flexible: connector vs parser
--   - connector:
--     - storage: Couchbase, MongoDB, MySQL, Oracle, PostgreSQL, SQLServer, SQLite
--   - parser:
--     - format: SQL, Prisma, Json, AML
--     - location: Local, Remote, Editor
-- also, fetch local file with gateway?


type SourceKind
    = DatabaseConnection DatabaseUrl
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
        DatabaseConnection _ ->
            True

        _ ->
            False


path : SourceKind -> String
path sourceContent =
    case sourceContent of
        DatabaseConnection url ->
            url

        SqlLocalFile name _ _ ->
            name

        SqlRemoteFile url _ ->
            url

        PrismaLocalFile name _ _ ->
            name

        PrismaRemoteFile url _ ->
            url

        JsonLocalFile name _ _ ->
            name

        JsonRemoteFile url _ ->
            url

        AmlEditor ->
            ""


same : SourceKind -> SourceKind -> Bool
same k2 k1 =
    case ( k1, k2 ) of
        ( DatabaseConnection _, DatabaseConnection _ ) ->
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
        DatabaseConnection _ ->
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
        DatabaseConnection url ->
            Encode.notNullObject
                [ ( "kind", "DatabaseConnection" |> Encode.string )
                , ( "url", url |> DatabaseUrl.encode )
                ]

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


encodeLocal : String -> FileName -> FileSize -> FileUpdatedAt -> Value
encodeLocal kind name size modified =
    Encode.notNullObject
        [ ( "kind", kind |> Encode.string )
        , ( "name", name |> FileName.encode )
        , ( "size", size |> FileSize.encode )
        , ( "modified", modified |> FileUpdatedAt.encode )
        ]


encodeRemote : String -> FileUrl -> FileSize -> Value
encodeRemote kind name size =
    Encode.notNullObject
        [ ( "kind", kind |> Encode.string )
        , ( "url", name |> FileUrl.encode )
        , ( "size", size |> FileSize.encode )
        ]


decode : Decode.Decoder SourceKind
decode =
    Decode.matchOn "kind"
        (\kind ->
            case kind of
                "DatabaseConnection" ->
                    decodeDatabaseConnection

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


decodeDatabaseConnection : Decode.Decoder SourceKind
decodeDatabaseConnection =
    Decode.map DatabaseConnection
        (Decode.field "url" DatabaseUrl.decode)


decodeLocalFile : Decode.Decoder ( FileName, FileSize, FileUpdatedAt )
decodeLocalFile =
    Decode.map3 Tuple3.new
        (Decode.field "name" FileName.decode)
        (Decode.field "size" FileSize.decode)
        (Decode.field "modified" FileUpdatedAt.decode)


decodeRemoteFile : Decode.Decoder ( FileUrl, FileSize )
decodeRemoteFile =
    Decode.map2 Tuple.new
        (Decode.field "url" FileUrl.decode)
        (Decode.field "size" FileSize.decode)
