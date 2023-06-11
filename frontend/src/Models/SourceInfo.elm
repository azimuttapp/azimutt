module Models.SourceInfo exposing (SourceInfo, aml, database, jsonLocal, jsonRemote, prismaLocal, prismaRemote, sqlLocal, sqlRemote)

import FileValue exposing (File)
import Libs.Models exposing (FileContent)
import Libs.Models.DatabaseUrl as DatabaseUrl exposing (DatabaseUrl)
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


database : Time.Posix -> SourceId -> DatabaseUrl -> SourceInfo
database now sourceId url =
    SourceInfo sourceId (DatabaseUrl.databaseName url) (DatabaseConnection url) True Nothing now now


aml : Time.Posix -> SourceId -> SourceName -> SourceInfo
aml now sourceId name =
    SourceInfo sourceId name AmlEditor True Nothing now now


sqlLocal : Time.Posix -> SourceId -> File -> SourceInfo
sqlLocal now sourceId file =
    SourceInfo sourceId file.name (SqlLocalFile file.name file.size file.lastModified) True Nothing now now


sqlRemote : Time.Posix -> SourceId -> FileUrl -> FileContent -> Maybe SampleKey -> SourceInfo
sqlRemote now sourceId url content sample =
    SourceInfo sourceId (url |> FileUrl.filename) (SqlRemoteFile url (String.length content)) True sample now now


prismaLocal : Time.Posix -> SourceId -> File -> SourceInfo
prismaLocal now sourceId file =
    SourceInfo sourceId file.name (PrismaLocalFile file.name file.size file.lastModified) True Nothing now now


prismaRemote : Time.Posix -> SourceId -> FileUrl -> FileContent -> Maybe SampleKey -> SourceInfo
prismaRemote now sourceId url content sample =
    SourceInfo sourceId (url |> FileUrl.filename) (PrismaRemoteFile url (String.length content)) True sample now now


jsonLocal : Time.Posix -> SourceId -> File -> SourceInfo
jsonLocal now sourceId file =
    SourceInfo sourceId file.name (JsonLocalFile file.name file.size file.lastModified) True Nothing now now


jsonRemote : Time.Posix -> SourceId -> FileUrl -> FileContent -> Maybe SampleKey -> SourceInfo
jsonRemote now sourceId url content sample =
    SourceInfo sourceId (url |> FileUrl.filename) (JsonRemoteFile url (String.length content)) True sample now now
