module PagesComponents.Projects.Id_.Models.EmbedKind exposing (EmbedKind(..), all, fromValue, label, placeholder, projectId, projectUrl, sourceUrl, value)


type EmbedKind
    = EmbedProjectId
    | EmbedProjectUrl
    | EmbedSourceUrl


all : List EmbedKind
all =
    [ EmbedProjectId, EmbedProjectUrl, EmbedSourceUrl ]


label : EmbedKind -> String
label kind =
    case kind of
        EmbedProjectId ->
            "Project id"

        EmbedProjectUrl ->
            "Project url"

        EmbedSourceUrl ->
            "Source url"


placeholder : EmbedKind -> String
placeholder kind =
    case kind of
        EmbedProjectId ->
            "00000000-0000-0000-0000-000000000000"

        EmbedProjectUrl ->
            "https://azimutt.app/samples/gospeak.azimutt.json"

        EmbedSourceUrl ->
            "https://azimutt.app/samples/gospeak.sql"


value : EmbedKind -> String
value kind =
    case kind of
        EmbedProjectId ->
            projectId

        EmbedProjectUrl ->
            projectUrl

        EmbedSourceUrl ->
            sourceUrl


fromValue : String -> Maybe EmbedKind
fromValue kind =
    if kind == projectId then
        Just EmbedProjectId

    else if kind == projectUrl then
        Just EmbedProjectUrl

    else if kind == sourceUrl then
        Just EmbedSourceUrl

    else
        Nothing


projectId : String
projectId =
    "project-id"


projectUrl : String
projectUrl =
    "project-url"


sourceUrl : String
sourceUrl =
    "source-url"
