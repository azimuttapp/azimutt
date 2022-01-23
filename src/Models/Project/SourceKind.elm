module Models.Project.SourceKind exposing (SourceKind(..), decode, encode, path, same)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Models.FileName as FileName exposing (FileName)
import Libs.Models.FileSize as FileSize exposing (FileSize)
import Libs.Models.FileUpdatedAt as FileUpdatedAt exposing (FileUpdatedAt)
import Libs.Models.FileUrl as FileUrl exposing (FileUrl)


type SourceKind
    = LocalFile FileName FileSize FileUpdatedAt
    | RemoteFile FileUrl FileSize
    | UserDefined


path : SourceKind -> String
path sourceContent =
    case sourceContent of
        LocalFile name _ _ ->
            name

        RemoteFile url _ ->
            url

        UserDefined ->
            ""


same : SourceKind -> SourceKind -> Bool
same k2 k1 =
    case ( k1, k2 ) of
        ( LocalFile _ _ _, LocalFile _ _ _ ) ->
            True

        ( RemoteFile _ _, RemoteFile _ _ ) ->
            True

        ( UserDefined, UserDefined ) ->
            True

        _ ->
            False


encode : SourceKind -> Value
encode value =
    case value of
        LocalFile name size modified ->
            E.notNullObject
                [ ( "kind", "LocalFile" |> Encode.string )
                , ( "name", name |> FileName.encode )
                , ( "size", size |> FileSize.encode )
                , ( "modified", modified |> FileUpdatedAt.encode )
                ]

        RemoteFile name size ->
            E.notNullObject
                [ ( "kind", "RemoteFile" |> Encode.string )
                , ( "url", name |> FileUrl.encode )
                , ( "size", size |> FileSize.encode )
                ]

        UserDefined ->
            E.notNullObject [ ( "kind", "UserDefined" |> Encode.string ) ]


decode : Decode.Decoder SourceKind
decode =
    D.matchOn "kind"
        (\kind ->
            case kind of
                "LocalFile" ->
                    Decode.map3 LocalFile
                        (Decode.field "name" FileName.decode)
                        (Decode.field "size" FileSize.decode)
                        (Decode.field "modified" FileUpdatedAt.decode)

                "RemoteFile" ->
                    Decode.map2 RemoteFile
                        (Decode.field "url" FileUrl.decode)
                        (Decode.field "size" FileSize.decode)

                "UserDefined" ->
                    Decode.succeed UserDefined

                other ->
                    Decode.fail ("Not supported kind of SourceKind '" ++ other ++ "'")
        )
