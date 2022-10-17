module Models.SourceInfo exposing (SourceInfo, aml, jsonLocal, jsonRemote, sqlLocal, sqlRemote)

import FileValue exposing (File)
import Libs.Models exposing (FileContent)
import Libs.Models.FileUrl as FileUrl exposing (FileUrl)
import Models.Project.SampleKey exposing (SampleKey)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
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


aml : Time.Posix -> SourceId -> SourceName -> SourceInfo
aml now sourceId name =
    SourceInfo sourceId name AmlEditor True Nothing now now


sqlLocal : Time.Posix -> SourceId -> File -> SourceInfo
sqlLocal now sourceId file =
    SourceInfo sourceId file.name (SqlLocalFile file.name file.size file.lastModified) True Nothing now now


sqlRemote : Time.Posix -> SourceId -> FileUrl -> FileContent -> Maybe SampleKey -> SourceInfo
sqlRemote now sourceId url content sample =
    SourceInfo sourceId (url |> FileUrl.filename) (SqlRemoteFile url (String.length content)) True sample now now


jsonLocal : Time.Posix -> SourceId -> File -> SourceInfo
jsonLocal now sourceId file =
    SourceInfo sourceId file.name (JsonLocalFile file.name file.size file.lastModified) True Nothing now now


jsonRemote : Time.Posix -> SourceId -> FileUrl -> FileContent -> Maybe SampleKey -> SourceInfo
jsonRemote now sourceId url content sample =
    SourceInfo sourceId (url |> FileUrl.filename) (JsonRemoteFile url (String.length content)) True sample now now
