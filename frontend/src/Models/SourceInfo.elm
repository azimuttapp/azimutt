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


database : Time.Posix -> SourceId -> SourceName -> DatabaseKind -> DatabaseUrl -> DatabaseUrlStorage -> SourceInfo
database now sourceId name engine url storage =
    let
        ( sourceName, kind ) =
            ( name |> String.nonEmptyMaybe |> Maybe.withDefault (DatabaseUrl.databaseName url), { kind = engine, url = Just url, storage = storage } )
    in
    SourceInfo sourceId sourceName (DatabaseConnection kind) True Nothing now now


aml : Time.Posix -> SourceId -> SourceName -> SourceInfo
aml now sourceId name =
    SourceInfo sourceId name AmlEditor True Nothing now now


sqlLocal : Time.Posix -> SourceId -> SourceName -> File -> SourceInfo
sqlLocal now sourceId name file =
    let
        ( sourceName, kind ) =
            ( name |> String.nonEmptyMaybe |> Maybe.withDefault file.name, { name = file.name, size = file.size, modified = file.lastModified } )
    in
    SourceInfo sourceId sourceName (SqlLocalFile kind) True Nothing now now


sqlRemote : Time.Posix -> SourceId -> SourceName -> FileUrl -> FileContent -> Maybe SampleKey -> SourceInfo
sqlRemote now sourceId name url content sample =
    let
        ( sourceName, kind ) =
            ( name |> String.nonEmptyMaybe |> Maybe.withDefault (url |> FileUrl.filename), { url = url, size = String.length content } )
    in
    SourceInfo sourceId sourceName (SqlRemoteFile kind) True sample now now


prismaLocal : Time.Posix -> SourceId -> SourceName -> File -> SourceInfo
prismaLocal now sourceId name file =
    let
        ( sourceName, kind ) =
            ( name |> String.nonEmptyMaybe |> Maybe.withDefault file.name, { name = file.name, size = file.size, modified = file.lastModified } )
    in
    SourceInfo sourceId sourceName (PrismaLocalFile kind) True Nothing now now


prismaRemote : Time.Posix -> SourceId -> SourceName -> FileUrl -> FileContent -> Maybe SampleKey -> SourceInfo
prismaRemote now sourceId name url content sample =
    let
        ( sourceName, kind ) =
            ( name |> String.nonEmptyMaybe |> Maybe.withDefault (url |> FileUrl.filename), { url = url, size = String.length content } )
    in
    SourceInfo sourceId sourceName (PrismaRemoteFile kind) True sample now now


jsonLocal : Time.Posix -> SourceId -> SourceName -> File -> SourceInfo
jsonLocal now sourceId name file =
    let
        ( sourceName, kind ) =
            ( name |> String.nonEmptyMaybe |> Maybe.withDefault file.name, { name = file.name, size = file.size, modified = file.lastModified } )
    in
    SourceInfo sourceId sourceName (JsonLocalFile kind) True Nothing now now


jsonRemote : Time.Posix -> SourceId -> SourceName -> FileUrl -> FileContent -> Maybe SampleKey -> SourceInfo
jsonRemote now sourceId name url content sample =
    let
        ( sourceName, kind ) =
            ( name |> String.nonEmptyMaybe |> Maybe.withDefault (url |> FileUrl.filename), { url = url, size = String.length content } )
    in
    SourceInfo sourceId sourceName (JsonRemoteFile kind) True sample now now
