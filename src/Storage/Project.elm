module Storage.Project exposing (decode, encode, encodeId)

import Json.Decode as Decode exposing (Value)
import Models.Project exposing (Project, ProjectId)
import Storage.ProjectV1 as ProjectV1
import Storage.ProjectV2 as ProjectV2


decode : Decode.Decoder Project
decode =
    Decode.field "version" Decode.int
        |> Decode.andThen
            (\v ->
                case v of
                    1 ->
                        ProjectV1.decodeProject |> Decode.map ProjectV1.upgrade

                    _ ->
                        ProjectV2.decodeProject
            )


encode : Project -> Value
encode value =
    ProjectV2.encodeProject value


encodeId : ProjectId -> Value
encodeId value =
    ProjectV2.encodeProjectId value
