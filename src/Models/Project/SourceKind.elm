module Models.Project.SourceKind exposing (SourceKind(..), decode, encode, path)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Json.Formats exposing (decodeFileModified, decodeFileName, decodeFileSize, decodeFileUrl, encodeFileModified, encodeFileName, encodeFileSize, encodeFileUrl)
import Libs.Models exposing (FileModified, FileName, FileSize, FileUrl)


type SourceKind
    = LocalFile FileName FileSize FileModified
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


encode : SourceKind -> Value
encode value =
    case value of
        LocalFile name size modified ->
            E.object
                [ ( "kind", "LocalFile" |> Encode.string )
                , ( "name", name |> encodeFileName )
                , ( "size", size |> encodeFileSize )
                , ( "modified", modified |> encodeFileModified )
                ]

        RemoteFile name size ->
            E.object
                [ ( "kind", "RemoteFile" |> Encode.string )
                , ( "url", name |> encodeFileUrl )
                , ( "size", size |> encodeFileSize )
                ]

        UserDefined ->
            E.object [ ( "kind", "UserDefined" |> Encode.string ) ]


decode : Decode.Decoder SourceKind
decode =
    D.matchOn "kind"
        (\kind ->
            case kind of
                "LocalFile" ->
                    Decode.map3 LocalFile
                        (Decode.field "name" decodeFileName)
                        (Decode.field "size" decodeFileSize)
                        (Decode.field "modified" decodeFileModified)

                "RemoteFile" ->
                    Decode.map2 RemoteFile
                        (Decode.field "url" decodeFileUrl)
                        (Decode.field "size" decodeFileSize)

                "UserDefined" ->
                    Decode.succeed UserDefined

                other ->
                    Decode.fail ("Not supported kind of SourceKind '" ++ other ++ "'")
        )
