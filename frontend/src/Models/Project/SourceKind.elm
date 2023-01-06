module Models.Project.SourceKind exposing (SourceKind(..), decode, encode, isUser, path, same, toString)

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
    = DatabaseConnection DatabaseUrl
    | SqlLocalFile FileName FileSize FileUpdatedAt
    | SqlRemoteFile FileUrl FileSize
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


path : SourceKind -> String
path sourceContent =
    case sourceContent of
        DatabaseConnection url ->
            url

        SqlLocalFile name _ _ ->
            name

        SqlRemoteFile url _ ->
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
            Encode.notNullObject
                [ ( "kind", "SqlLocalFile" |> Encode.string )
                , ( "name", name |> FileName.encode )
                , ( "size", size |> FileSize.encode )
                , ( "modified", modified |> FileUpdatedAt.encode )
                ]

        SqlRemoteFile name size ->
            Encode.notNullObject
                [ ( "kind", "SqlRemoteFile" |> Encode.string )
                , ( "url", name |> FileUrl.encode )
                , ( "size", size |> FileSize.encode )
                ]

        JsonLocalFile name size modified ->
            Encode.notNullObject
                [ ( "kind", "JsonLocalFile" |> Encode.string )
                , ( "name", name |> FileName.encode )
                , ( "size", size |> FileSize.encode )
                , ( "modified", modified |> FileUpdatedAt.encode )
                ]

        JsonRemoteFile name size ->
            Encode.notNullObject
                [ ( "kind", "JsonRemoteFile" |> Encode.string )
                , ( "url", name |> FileUrl.encode )
                , ( "size", size |> FileSize.encode )
                ]

        AmlEditor ->
            Encode.notNullObject [ ( "kind", "AmlEditor" |> Encode.string ) ]


decode : Decode.Decoder SourceKind
decode =
    Decode.matchOn "kind"
        (\kind ->
            case kind of
                "DatabaseConnection" ->
                    decodeDatabaseConnection

                "SqlLocalFile" ->
                    decodeSqlLocalFile

                "SqlRemoteFile" ->
                    decodeSqlRemoteFile

                "JsonLocalFile" ->
                    decodeJsonLocalFile

                "JsonRemoteFile" ->
                    decodeJsonRemoteFile

                "AmlEditor" ->
                    decodeAmlEditor

                -- legacy names:
                "LocalFile" ->
                    decodeSqlLocalFile

                "RemoteFile" ->
                    decodeSqlRemoteFile

                "UserDefined" ->
                    decodeAmlEditor

                other ->
                    Decode.fail ("Not supported kind of SourceKind '" ++ other ++ "'")
        )


decodeDatabaseConnection : Decode.Decoder SourceKind
decodeDatabaseConnection =
    Decode.map DatabaseConnection
        (Decode.field "url" DatabaseUrl.decode)


decodeSqlLocalFile : Decode.Decoder SourceKind
decodeSqlLocalFile =
    Decode.map3 SqlLocalFile
        (Decode.field "name" FileName.decode)
        (Decode.field "size" FileSize.decode)
        (Decode.field "modified" FileUpdatedAt.decode)


decodeSqlRemoteFile : Decode.Decoder SourceKind
decodeSqlRemoteFile =
    Decode.map2 SqlRemoteFile
        (Decode.field "url" FileUrl.decode)
        (Decode.field "size" FileSize.decode)


decodeJsonLocalFile : Decode.Decoder SourceKind
decodeJsonLocalFile =
    Decode.map3 JsonLocalFile
        (Decode.field "name" FileName.decode)
        (Decode.field "size" FileSize.decode)
        (Decode.field "modified" FileUpdatedAt.decode)


decodeJsonRemoteFile : Decode.Decoder SourceKind
decodeJsonRemoteFile =
    Decode.map2 JsonRemoteFile
        (Decode.field "url" FileUrl.decode)
        (Decode.field "size" FileSize.decode)


decodeAmlEditor : Decode.Decoder SourceKind
decodeAmlEditor =
    Decode.succeed AmlEditor
