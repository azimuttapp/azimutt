module Services.SourceReader exposing (local, remote)

import Libs.FileInput exposing (File)
import Libs.List as L
import Libs.Models exposing (FileContent)
import Libs.Models.FileUrl exposing (FileUrl)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.SampleName exposing (SampleKey)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.SourceInfo exposing (SourceInfo)
import Time


local : Time.Posix -> ProjectId -> SourceId -> File -> FileContent -> (ProjectId -> SourceInfo -> FileContent -> msg) -> msg
local now projectId sourceId file content buildMsg =
    buildMsg projectId (SourceInfo sourceId (lastSegment file.name) (localSource file) True Nothing now now) content


remote : Time.Posix -> ProjectId -> SourceId -> FileUrl -> FileContent -> Maybe SampleKey -> (ProjectId -> SourceInfo -> FileContent -> msg) -> msg
remote now projectId sourceId url content sample buildMsg =
    buildMsg projectId (SourceInfo sourceId (lastSegment url) (remoteSource url content) True sample now now) content


localSource : File -> SourceKind
localSource file =
    LocalFile file.name file.size file.lastModified


remoteSource : FileUrl -> FileContent -> SourceKind
remoteSource url content =
    RemoteFile url (String.length content)


lastSegment : String -> String
lastSegment path =
    path |> String.split "/" |> List.filter (\p -> not (p == "")) |> L.last |> Maybe.withDefault path
