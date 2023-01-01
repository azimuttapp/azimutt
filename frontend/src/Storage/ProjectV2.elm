module Storage.ProjectV2 exposing (decodeProject)

import Json.Decode as Decode
import Models.Project as Project exposing (Project)


decodeProject : Decode.Decoder Project
decodeProject =
    Decode.field "version" Decode.int
        |> Decode.andThen
            (\v ->
                case v of
                    1 ->
                        Decode.fail "Version 1 of project is not supported anymore."

                    2 ->
                        Project.decode

                    _ ->
                        Decode.fail ("Unknown project version " ++ String.fromInt v ++ ".")
            )
