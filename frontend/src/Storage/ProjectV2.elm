module Storage.ProjectV2 exposing (decodeProject)

import Json.Decode as Decode
import Models.Project as Project exposing (Project)
import Storage.ProjectV1 as ProjectV1


decodeProject : Decode.Decoder Project
decodeProject =
    Decode.field "version" Decode.int
        |> Decode.andThen
            (\v ->
                case v of
                    1 ->
                        ProjectV1.decodeProject |> Decode.map ProjectV1.upgrade

                    _ ->
                        Project.decode
            )
