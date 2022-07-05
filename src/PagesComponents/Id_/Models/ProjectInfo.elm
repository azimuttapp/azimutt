module PagesComponents.Id_.Models.ProjectInfo exposing (ProjectInfo, create, decode, encode)

import Dict
import Json.Decode as Decode exposing (Value)
import Json.Encode as Encode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Time as Time
import Models.Project exposing (Project)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.ProjectName as ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)
import Time


type alias ProjectInfo =
    { id : ProjectId
    , name : ProjectName
    , tables : Int
    , relations : Int
    , layouts : Int
    , storage : ProjectStorage
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


create : Project -> ProjectInfo
create project =
    { id = project.id
    , name = project.name
    , tables = project.sources |> List.concatMap (\s -> s.tables |> Dict.keys) |> List.unique |> List.length
    , relations = project.sources |> List.foldl (\s acc -> acc + (s.relations |> List.length)) 0
    , layouts = project.layouts |> Dict.size
    , storage = project.storage
    , createdAt = project.createdAt
    , updatedAt = project.updatedAt
    }


encode : ProjectInfo -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> ProjectId.encode )
        , ( "name", value.name |> ProjectName.encode )
        , ( "tables", value.tables |> Encode.int )
        , ( "relations", value.relations |> Encode.int )
        , ( "layouts", value.layouts |> Encode.int )
        , ( "storage", value.storage |> ProjectStorage.encode )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        ]


decode : Decode.Decoder ProjectInfo
decode =
    Decode.map8 ProjectInfo
        (Decode.field "id" ProjectId.decode)
        (Decode.field "name" ProjectName.decode)
        (Decode.field "tables" Decode.int)
        (Decode.field "relations" Decode.int)
        (Decode.field "layouts" Decode.int)
        (Decode.field "storage" ProjectStorage.decode)
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)
