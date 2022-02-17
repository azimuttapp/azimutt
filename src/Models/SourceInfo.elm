module Models.SourceInfo exposing (SourceInfo)

import Models.Project.SampleKey exposing (SampleKey)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind)
import Models.Project.SourceName exposing (SourceName)
import Time


type alias SourceInfo =
    { id : SourceId
    , name : SourceName
    , kind : SourceKind
    , enabled : Bool
    , fromSample : Maybe SampleKey
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }
