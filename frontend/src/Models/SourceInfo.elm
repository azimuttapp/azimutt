module Models.SourceInfo exposing (SourceInfo, aml, database, jsonLocal, jsonRemote, prismaLocal, prismaRemote, sqlLocal, sqlRemote)

import FileValue exposing (File)
import Libs.Models exposing (FileContent)
import Libs.Models.DatabaseKind exposing (DatabaseKind)
import Libs.Models.DatabaseUrl as DatabaseUrl exposing (DatabaseUrl)
import Libs.Models.FileUrl as FileUrl exposing (FileUrl)
import Libs.String as String
import Models.Project.DatabaseUrlStorage exposing (DatabaseUrlStorage)
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


database : Time.Posix -> SourceId -> String -> DatabaseKind -> DatabaseUrl -> DatabaseUrlStorage -> SourceInfo
database now sourceId name engine url storage =
    let
        ( sourceName, kind ) =
            ( name |> String.nonEmptyMaybe |> Maybe.withDefault (DatabaseUrl.databaseName url)
            , DatabaseConnection { kind = engine, url = Just url, storage = storage }
            )
    in
    SourceInfo sourceId sourceName kind True Nothing now now


aml : Time.Posix -> SourceId -> SourceName -> SourceInfo
aml now sourceId name =
    SourceInfo sourceId name AmlEditor True Nothing now now


sqlLocal : Time.Posix -> SourceId -> File -> SourceInfo
sqlLocal now sourceId file =
    SourceInfo sourceId file.name (SqlLocalFile { name = file.name, size = file.size, modified = file.lastModified }) True Nothing now now


sqlRemote : Time.Posix -> SourceId -> FileUrl -> FileContent -> Maybe SampleKey -> SourceInfo
sqlRemote now sourceId url content sample =
    SourceInfo sourceId (url |> FileUrl.filename) (SqlRemoteFile { url = url, size = String.length content }) True sample now now


prismaLocal : Time.Posix -> SourceId -> File -> SourceInfo
prismaLocal now sourceId file =
    SourceInfo sourceId file.name (PrismaLocalFile { name = file.name, size = file.size, modified = file.lastModified }) True Nothing now now


prismaRemote : Time.Posix -> SourceId -> FileUrl -> FileContent -> Maybe SampleKey -> SourceInfo
prismaRemote now sourceId url content sample =
    SourceInfo sourceId (url |> FileUrl.filename) (PrismaRemoteFile { url = url, size = String.length content }) True sample now now


jsonLocal : Time.Posix -> SourceId -> File -> SourceInfo
jsonLocal now sourceId file =
    SourceInfo sourceId file.name (JsonLocalFile { name = file.name, size = file.size, modified = file.lastModified }) True Nothing now now


jsonRemote : Time.Posix -> SourceId -> FileUrl -> FileContent -> Maybe SampleKey -> SourceInfo
jsonRemote now sourceId url content sample =
    SourceInfo sourceId (url |> FileUrl.filename) (JsonRemoteFile { url = url, size = String.length content }) True sample now now
