module Models.Project.SourceKind exposing (SourceKind(..), decode, encode, isUser, path, same)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Models.DatabaseUrl as DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.FileName as FileName exposing (FileName)
import Libs.Models.FileSize as FileSize exposing (FileSize)
import Libs.Models.FileUpdatedAt as FileUpdatedAt exposing (FileUpdatedAt)
import Libs.Models.FileUrl as FileUrl exposing (FileUrl)


type SourceKind
    = SqlFileLocal FileName FileSize FileUpdatedAt
    | SqlFileRemote FileUrl FileSize
    | DatabaseConnection DatabaseUrl
    | JsonFileLocal FileName FileSize FileUpdatedAt
    | JsonFileRemote FileUrl FileSize
    | AmlEditor


isUser : SourceKind -> Bool
isUser kind =
    case kind of
        AmlEditor ->
            True

        _ ->
            False


path : SourceKind -> String
path sourceContent =
    case sourceContent of
        SqlFileLocal name _ _ ->
            name

        SqlFileRemote url _ ->
            url

        DatabaseConnection url ->
            url

        JsonFileLocal name _ _ ->
            name

        JsonFileRemote url _ ->
            url

        AmlEditor ->
            ""


same : SourceKind -> SourceKind -> Bool
same k2 k1 =
    case ( k1, k2 ) of
        ( SqlFileLocal _ _ _, SqlFileLocal _ _ _ ) ->
            True

        ( SqlFileRemote _ _, SqlFileRemote _ _ ) ->
            True

        ( DatabaseConnection _, DatabaseConnection _ ) ->
            True

        ( AmlEditor, AmlEditor ) ->
            True

        _ ->
            False


encode : SourceKind -> Value
encode value =
    case value of
        SqlFileLocal name size modified ->
            Encode.notNullObject
                [ ( "kind", "SqlFileLocal" |> Encode.string )
                , ( "name", name |> FileName.encode )
                , ( "size", size |> FileSize.encode )
                , ( "modified", modified |> FileUpdatedAt.encode )
                ]

        SqlFileRemote name size ->
            Encode.notNullObject
                [ ( "kind", "SqlFileRemote" |> Encode.string )
                , ( "url", name |> FileUrl.encode )
                , ( "size", size |> FileSize.encode )
                ]

        DatabaseConnection url ->
            Encode.notNullObject
                [ ( "kind", "DatabaseConnection" |> Encode.string )
                , ( "url", url |> DatabaseUrl.encode )
                ]

        JsonFileLocal name size modified ->
            Encode.notNullObject
                [ ( "kind", "JsonFileLocal" |> Encode.string )
                , ( "name", name |> FileName.encode )
                , ( "size", size |> FileSize.encode )
                , ( "modified", modified |> FileUpdatedAt.encode )
                ]

        JsonFileRemote name size ->
            Encode.notNullObject
                [ ( "kind", "JsonFileRemote" |> Encode.string )
                , ( "url", name |> FileUrl.encode )
                , ( "size", size |> FileSize.encode )
                ]

        AmlEditor ->
            Encode.notNullObject [ ( "kind", "UserDefined" |> Encode.string ) ]


decode : Decode.Decoder SourceKind
decode =
    Decode.matchOn "kind"
        (\kind ->
            case kind of
                "SqlFileLocal" ->
                    decodeSqlFileLocal

                "SqlFileRemote" ->
                    decodeSqlFileRemote

                "DatabaseConnection" ->
                    decodeDatabaseConnection

                "JsonFileLocal" ->
                    decodeJsonFileLocal

                "JsonFileRemote" ->
                    decodeJsonFileRemote

                "AmlEditor" ->
                    decodeAmlEditor

                -- legacy names:
                "LocalFile" ->
                    decodeSqlFileLocal

                "RemoteFile" ->
                    decodeSqlFileRemote

                "UserDefined" ->
                    decodeAmlEditor

                other ->
                    Decode.fail ("Not supported kind of SourceKind '" ++ other ++ "'")
        )


decodeSqlFileLocal : Decode.Decoder SourceKind
decodeSqlFileLocal =
    Decode.map3 SqlFileLocal
        (Decode.field "name" FileName.decode)
        (Decode.field "size" FileSize.decode)
        (Decode.field "modified" FileUpdatedAt.decode)


decodeSqlFileRemote : Decode.Decoder SourceKind
decodeSqlFileRemote =
    Decode.map2 SqlFileRemote
        (Decode.field "url" FileUrl.decode)
        (Decode.field "size" FileSize.decode)


decodeDatabaseConnection : Decode.Decoder SourceKind
decodeDatabaseConnection =
    Decode.map DatabaseConnection
        (Decode.field "url" DatabaseUrl.decode)


decodeJsonFileLocal : Decode.Decoder SourceKind
decodeJsonFileLocal =
    Decode.map3 JsonFileLocal
        (Decode.field "name" FileName.decode)
        (Decode.field "size" FileSize.decode)
        (Decode.field "modified" FileUpdatedAt.decode)


decodeJsonFileRemote : Decode.Decoder SourceKind
decodeJsonFileRemote =
    Decode.map2 JsonFileRemote
        (Decode.field "url" FileUrl.decode)
        (Decode.field "size" FileSize.decode)


decodeAmlEditor : Decode.Decoder SourceKind
decodeAmlEditor =
    Decode.succeed AmlEditor
