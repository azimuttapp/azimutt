module Models.ProjectInfo exposing (ProjectInfo, decode, encode, fromProject, icon, organizationId, title, zero)

import Components.Atoms.Icon as Icon
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Maybe as Maybe
import Libs.Time as Time
import Models.Organization as Organization exposing (Organization)
import Models.OrganizationId as OrganizationId exposing (OrganizationId)
import Models.Project as Project exposing (Project)
import Models.Project.Metadata as Metadata
import Models.Project.ProjectEncodingVersion as ProjectEncodingVersion exposing (ProjectEncodingVersion)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.ProjectName as ProjectName exposing (ProjectName)
import Models.Project.ProjectSlug as ProjectSlug exposing (ProjectSlug)
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)
import Models.Project.ProjectVisibility as ProjectVisibility exposing (ProjectVisibility)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Time


type alias ProjectInfo =
    { organization : Maybe Organization
    , id : ProjectId
    , slug : ProjectSlug
    , name : ProjectName
    , description : Maybe String
    , storage : ProjectStorage
    , visibility : ProjectVisibility
    , version : ProjectEncodingVersion
    , nbSources : Int
    , nbTables : Int
    , nbColumns : Int
    , nbRelations : Int
    , nbTypes : Int
    , nbComments : Int
    , nbLayouts : Int
    , nbNotes : Int
    , nbMemos : Int
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


zero : ProjectInfo
zero =
    { organization = Nothing
    , id = ProjectId.zero
    , slug = "zero"
    , name = "Zero"
    , description = Nothing
    , storage = ProjectStorage.Local
    , visibility = ProjectVisibility.None
    , version = ProjectEncodingVersion.current
    , nbSources = 0
    , nbTables = 0
    , nbColumns = 0
    , nbRelations = 0
    , nbTypes = 0
    , nbComments = 0
    , nbLayouts = 0
    , nbNotes = 0
    , nbMemos = 0
    , createdAt = Time.zero
    , updatedAt = Time.zero
    }


fromProject : Project -> ProjectInfo
fromProject p =
    let
        tables : Dict TableId (List Table)
        tables =
            p |> Project.tables
    in
    { organization = p.organization
    , id = p.id
    , slug = p.slug
    , name = p.name
    , description = p.description
    , storage = p.storage
    , visibility = p.visibility
    , version = p.version
    , nbSources = p.sources |> List.length
    , nbTables = tables |> Dict.size
    , nbColumns = tables |> Dict.values |> List.map (List.map (.columns >> Dict.size) >> List.maximum >> Maybe.withDefault 0) |> List.sum
    , nbRelations = p |> Project.relations |> Dict.size
    , nbTypes = p |> Project.types |> Dict.size
    , nbComments = p.sources |> List.concatMap (.tables >> Dict.values >> List.concatMap (\t -> t.comment :: (t.columns |> Dict.values |> List.map .comment) |> List.filterMap identity)) |> List.length
    , nbLayouts = p.layouts |> Dict.size
    , nbNotes = p.metadata |> Metadata.countNotes
    , nbMemos = p.layouts |> Dict.values |> List.concatMap .memos |> List.length
    , createdAt = p.createdAt
    , updatedAt = p.updatedAt
    }


organizationId : ProjectInfo -> OrganizationId
organizationId p =
    p.organization |> Maybe.mapOrElse .id OrganizationId.zero


icon : ProjectInfo -> Icon.Icon
icon project =
    -- should stay sync with backend/lib/azimutt_web/templates/organization/_project_icon.html.heex
    if project.storage == ProjectStorage.Local then
        Icon.Folder

    else if project.visibility /= ProjectVisibility.None then
        Icon.GlobeAlt

    else if (project.organization |> Maybe.andThen .cleverCloud) /= Nothing then
        Icon.Puzzle

    else if (project.organization |> Maybe.andThen .heroku) /= Nothing then
        Icon.Puzzle

    else
        Icon.Cloud


title : ProjectInfo -> String
title project =
    if project.storage == ProjectStorage.Local then
        "Local project"

    else if project.visibility /= ProjectVisibility.None then
        "Public project"

    else if (project.organization |> Maybe.andThen .cleverCloud) /= Nothing then
        "Clever Cloud Add-on project"

    else if (project.organization |> Maybe.andThen .heroku) /= Nothing then
        "Heroku Add-on project"

    else
        "Remote project"


encode : ProjectInfo -> Value
encode value =
    Encode.notNullObject
        [ ( "organization", value.organization |> Encode.maybe Organization.encode )
        , ( "id", value.id |> ProjectId.encode )
        , ( "slug", value.slug |> ProjectSlug.encode )
        , ( "name", value.name |> ProjectName.encode )
        , ( "description", value.description |> Encode.maybe Encode.string )
        , ( "storage", value.storage |> ProjectStorage.encode )
        , ( "visibility", value.visibility |> ProjectVisibility.encode )
        , ( "encodingVersion", value.version |> ProjectEncodingVersion.encode )
        , ( "nbSources", value.nbSources |> Encode.int )
        , ( "nbTables", value.nbTables |> Encode.int )
        , ( "nbColumns", value.nbColumns |> Encode.int )
        , ( "nbRelations", value.nbRelations |> Encode.int )
        , ( "nbTypes", value.nbTypes |> Encode.int )
        , ( "nbComments", value.nbComments |> Encode.int )
        , ( "nbLayouts", value.nbLayouts |> Encode.int )
        , ( "nbNotes", value.nbNotes |> Encode.int )
        , ( "nbMemos", value.nbMemos |> Encode.int )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        ]


decode : Decode.Decoder ProjectInfo
decode =
    Decode.map19 ProjectInfo
        (Decode.maybeField "organization" Organization.decode)
        (Decode.field "id" ProjectId.decode)
        (Decode.field "slug" ProjectSlug.decode)
        (Decode.field "name" ProjectName.decode)
        (Decode.maybeField "description" Decode.string)
        (Decode.field "storage" ProjectStorage.decode)
        (Decode.field "visibility" ProjectVisibility.decode)
        (Decode.field "encodingVersion" ProjectEncodingVersion.decode)
        (Decode.field "nbSources" Decode.int)
        (Decode.field "nbTables" Decode.int)
        (Decode.field "nbColumns" Decode.int)
        (Decode.field "nbRelations" Decode.int)
        (Decode.field "nbTypes" Decode.int)
        (Decode.field "nbComments" Decode.int)
        (Decode.field "nbLayouts" Decode.int)
        (Decode.field "nbNotes" Decode.int)
        (Decode.field "nbMemos" Decode.int)
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)
