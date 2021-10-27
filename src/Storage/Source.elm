module Storage.Source exposing (decodeId, encodeId)

import Json.Decode as Decode
import Json.Encode exposing (Value)
import Models.Project.SourceId exposing (SourceId)
import Storage.ProjectV2 as ProjectV2


encodeId : SourceId -> Value
encodeId value =
    ProjectV2.encodeSourceId value


decodeId : Decode.Decoder SourceId
decodeId =
    ProjectV2.decodeSourceId
