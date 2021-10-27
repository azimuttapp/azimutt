module Models.Project.SourceId exposing (SourceId, new, toString)

import Libs.Models exposing (UID)


type SourceId
    = SourceId UID


new : String -> SourceId
new id =
    SourceId id


toString : SourceId -> String
toString (SourceId id) =
    id
