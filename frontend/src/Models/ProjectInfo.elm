module Models.ProjectInfo exposing (ProjectInfo, decode, encode, fromProject, organizationId)

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Time as Time
import Models.Organization as Organization exposing (Organization)
import Models.OrganizationId as OrganizationId
import Models.Project exposing (Project)
import Models.Project.ProjectEncodingVersion as ProjectEncodingVersion exposing (ProjectEncodingVersion)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.ProjectName as ProjectName exposing (ProjectName)
import Models.Project.ProjectSlug as ProjectSlug exposing (ProjectSlug)
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)
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
    , version : ProjectEncodingVersion
    , nbSources : Int
    , nbTables : Int
    , nbColumns : Int
    , nbRelations : Int
    , nbTypes : Int
    , nbComments : Int
    , nbNotes : Int
    , nbLayouts : Int
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


fromProject : Project -> ProjectInfo
fromProject p =
    let
        -- should be the same as `computeStats` in ts-src/types/project.ts
        tables : Dict TableId (List Table)
        tables =
            p.sources |> List.concatMap (\s -> s.tables |> Dict.values) |> List.groupBy .id
    in
    { organization = p.organization
    , id = p.id
    , slug = p.slug
    , name = p.name
    , description = p.description
    , storage = p.storage
    , version = p.version
    , nbSources = p.sources |> List.length
    , nbTables = tables |> Dict.size
    , nbColumns = tables |> Dict.values |> List.map (List.map (.columns >> Dict.size) >> List.maximum >> Maybe.withDefault 0) |> List.sum
    , nbRelations = p.sources |> List.foldl (\src acc -> acc + (src.relations |> List.length)) 0
    , nbTypes = p.types |> Dict.size
    , nbComments = p.sources |> List.concatMap (.tables >> Dict.values >> List.concatMap (\t -> t.comment :: (t.columns |> Dict.values |> List.map .comment) |> List.filterMap identity)) |> List.length
    , nbNotes = p.notes |> Dict.size
    , nbLayouts = p.layouts |> Dict.size
    , createdAt = p.createdAt
    , updatedAt = p.updatedAt
    }


organizationId : ProjectInfo -> OrganizationId.OrganizationId
organizationId p =
    p.organization |> Maybe.mapOrElse .id OrganizationId.zero


encode : ProjectInfo -> Value
encode value =
    Encode.notNullObject
        [ ( "organization", value.organization |> Encode.maybe Organization.encode )
        , ( "id", value.id |> ProjectId.encode )
        , ( "slug", value.slug |> ProjectSlug.encode )
        , ( "name", value.name |> ProjectName.encode )
        , ( "description", value.description |> Encode.maybe Encode.string )
        , ( "storage", value.storage |> ProjectStorage.encode )
        , ( "encodingVersion", value.version |> ProjectEncodingVersion.encode )
        , ( "nbSources", value.nbSources |> Encode.int )
        , ( "nbTables", value.nbTables |> Encode.int )
        , ( "nbColumns", value.nbColumns |> Encode.int )
        , ( "nbRelations", value.nbRelations |> Encode.int )
        , ( "nbTypes", value.nbTypes |> Encode.int )
        , ( "nbComments", value.nbComments |> Encode.int )
        , ( "nbNotes", value.nbNotes |> Encode.int )
        , ( "nbLayouts", value.nbLayouts |> Encode.int )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        ]


decode : Decode.Decoder ProjectInfo
decode =
    Decode.map17 ProjectInfo
        (Decode.maybeField "organization" Organization.decode)
        (Decode.field "id" ProjectId.decode)
        (Decode.field "slug" ProjectSlug.decode)
        (Decode.field "name" ProjectName.decode)
        (Decode.maybeField "description" Decode.string)
        (Decode.field "storage" ProjectStorage.decode)
        (Decode.field "encodingVersion" ProjectEncodingVersion.decode)
        (Decode.field "nbSources" Decode.int)
        (Decode.field "nbTables" Decode.int)
        (Decode.field "nbColumns" Decode.int)
        (Decode.field "nbRelations" Decode.int)
        (Decode.field "nbTypes" Decode.int)
        (Decode.field "nbComments" Decode.int)
        (Decode.field "nbNotes" Decode.int)
        (Decode.field "nbLayouts" Decode.int)
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)
