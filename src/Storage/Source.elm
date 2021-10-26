module Storage.Source exposing (encodeId)

import Json.Encode exposing (Value)
import Models.Project.SourceId exposing (SourceId)
import Storage.ProjectV2 as ProjectV2


encodeId : SourceId -> Value
encodeId value =
    ProjectV2.encodeSourceId value
