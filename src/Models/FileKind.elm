module Models.FileKind exposing (FileKind(..), decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)


type FileKind
    = SqlSourceFile
    | ProjectFile


encode : FileKind -> Value
encode value =
    (case value of
        SqlSourceFile ->
            "sql-source-file"

        ProjectFile ->
            "project-file"
    )
        |> Encode.string


decode : Decode.Decoder FileKind
decode =
    Decode.string
        |> Decode.andThen
            (\value ->
                case value of
                    "sql-source-file" ->
                        Decode.succeed SqlSourceFile

                    "project-file" ->
                        Decode.succeed ProjectFile

                    _ ->
                        Decode.fail ("Invalid FileKind: " ++ value)
            )
