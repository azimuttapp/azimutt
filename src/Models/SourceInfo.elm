module Models.SourceInfo exposing (SourceInfo)

import Models.Project.SampleName exposing (SampleName)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind)
import Models.Project.SourceName exposing (SourceName)
import Time


type alias SourceInfo =
    { id : SourceId
    , name : SourceName
    , kind : SourceKind
    , enabled : Bool
    , fromSample : Maybe SampleName
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }
