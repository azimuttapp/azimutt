module PagesComponents.Projects.Id_.Models.EmbedKind exposing (EmbedKind(..), all, databaseSource, fromValue, jsonSource, label, placeholder, projectId, projectUrl, sourceUrl, sqlSource, value)

import Libs.Models.Uuid as Uuid


type EmbedKind
    = EmbedProjectId
    | EmbedProjectUrl
    | EmbedDatabaseSource
    | EmbedSqlSource
    | EmbedJsonSource


all : List EmbedKind
all =
    [ EmbedProjectId, EmbedProjectUrl, EmbedDatabaseSource, EmbedSqlSource, EmbedJsonSource ]


label : EmbedKind -> String
label kind =
    case kind of
        EmbedProjectId ->
            "Project id"

        EmbedProjectUrl ->
            "Project url"

        EmbedDatabaseSource ->
            "Database"

        EmbedSqlSource ->
            "SQL"

        EmbedJsonSource ->
            "JSON"


placeholder : EmbedKind -> String
placeholder kind =
    case kind of
        EmbedProjectId ->
            Uuid.zero

        EmbedProjectUrl ->
            "https://azimutt.app/samples/gospeak.azimutt.json"

        EmbedDatabaseSource ->
            "postgres://<user>:<password>@<host>:<port>/<db_name>"

        EmbedSqlSource ->
            "https://azimutt.app/samples/gospeak.sql"

        EmbedJsonSource ->
            "https://azimutt.app/samples/gospeak.json"


value : EmbedKind -> String
value kind =
    case kind of
        EmbedProjectId ->
            projectId

        EmbedProjectUrl ->
            projectUrl

        EmbedDatabaseSource ->
            databaseSource

        EmbedSqlSource ->
            sqlSource

        EmbedJsonSource ->
            jsonSource


fromValue : String -> Maybe EmbedKind
fromValue kind =
    if kind == projectId then
        Just EmbedProjectId

    else if kind == projectUrl then
        Just EmbedProjectUrl

    else if kind == databaseSource then
        Just EmbedDatabaseSource

    else if kind == sqlSource then
        Just EmbedSqlSource

    else if kind == jsonSource then
        Just EmbedJsonSource

    else
        Nothing


projectId : String
projectId =
    "project-id"


projectUrl : String
projectUrl =
    "project-url"


databaseSource : String
databaseSource =
    "database-source"


sqlSource : String
sqlSource =
    "sql-source"


jsonSource : String
jsonSource =
    "json-source"


sourceUrl : String
sourceUrl =
    "source-url"
