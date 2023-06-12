module PagesComponents.Organization_.Project_.Models.EmbedKind exposing (EmbedKind(..), all, databaseSource, fromValue, jsonSource, label, prismaSource, projectId, projectUrl, sourceUrl, sqlSource, value)


type EmbedKind
    = EmbedProjectId
    | EmbedProjectUrl
    | EmbedDatabaseSource
    | EmbedSqlSource
    | EmbedPrismaSource
    | EmbedJsonSource


all : List EmbedKind
all =
    [ EmbedProjectId, EmbedProjectUrl, EmbedDatabaseSource, EmbedSqlSource, EmbedPrismaSource, EmbedJsonSource ]


label : EmbedKind -> String
label kind =
    case kind of
        EmbedProjectId ->
            "Project id"

        EmbedProjectUrl ->
            "Project url"

        EmbedDatabaseSource ->
            "Database source"

        EmbedSqlSource ->
            "SQL source"

        EmbedPrismaSource ->
            "Prisma source"

        EmbedJsonSource ->
            "JSON source"


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

        EmbedPrismaSource ->
            prismaSource

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

    else if kind == prismaSource then
        Just EmbedPrismaSource

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


prismaSource : String
prismaSource =
    "prisma-source"


jsonSource : String
jsonSource =
    "json-source"


sourceUrl : String
sourceUrl =
    "source-url"
