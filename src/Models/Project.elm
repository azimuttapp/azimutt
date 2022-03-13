module Models.Project exposing (Project, compute, computeRelations, computeTables, create, decode, downloadContent, downloadFilename, encode, new)

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Dict as Dict
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Time as Time
import Models.Project.Layout as Layout exposing (Layout)
import Models.Project.LayoutName as LayoutName exposing (LayoutName)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.ProjectName as ProjectName exposing (ProjectName)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.Source as Source exposing (Source)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Time


type alias Project =
    { id : ProjectId
    , name : ProjectName
    , sources : List Source
    , tables : Dict TableId Table -- computed from sources, do not update directly (see compute function)
    , relations : List Relation -- computed from sources, do not update directly (see compute function)
    , layout : Layout
    , usedLayout : Maybe LayoutName
    , layouts : Dict LayoutName Layout
    , settings : ProjectSettings
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


new : ProjectId -> ProjectName -> List Source -> Layout -> Maybe LayoutName -> Dict LayoutName Layout -> ProjectSettings -> Time.Posix -> Time.Posix -> Project
new id name sources layout usedLayout layouts settings createdAt updatedAt =
    { id = id
    , name = name
    , sources = sources
    , tables = Dict.empty
    , relations = []
    , layout = layout
    , usedLayout = usedLayout
    , layouts = layouts
    , settings = settings
    , createdAt = createdAt
    , updatedAt = updatedAt
    }
        |> compute


create : ProjectId -> ProjectName -> Source -> Project
create id name source =
    new id name [ source ] (Layout.init source.createdAt) Nothing Dict.empty ProjectSettings.init source.createdAt source.updatedAt


compute : Project -> Project
compute project =
    (project.sources |> computeTables project.settings)
        |> (\tables -> { project | tables = tables, relations = project.sources |> computeRelations tables })


computeTables : ProjectSettings -> List Source -> Dict TableId Table
computeTables settings sources =
    sources
        |> List.filter .enabled
        |> List.map (\s -> s.tables |> Dict.filter (\_ -> shouldDisplayTable settings))
        |> List.foldr (Dict.fuse Table.merge) Dict.empty


shouldDisplayTable : ProjectSettings -> Table -> Bool
shouldDisplayTable settings table =
    let
        isSchemaRemoved : Bool
        isSchemaRemoved =
            settings.removedSchemas |> List.member table.schema

        isViewRemoved : Bool
        isViewRemoved =
            table.view && settings.removeViews

        isTableRemoved : Bool
        isTableRemoved =
            table.id |> ProjectSettings.removeTable settings.removedTables
    in
    not isSchemaRemoved && not isViewRemoved && not isTableRemoved


computeRelations : Dict TableId Table -> List Source -> List Relation
computeRelations tables sources =
    sources
        |> List.filter .enabled
        |> List.map (\s -> s.relations |> List.filter (shouldDisplayRelation tables))
        |> List.foldr (List.merge .id Relation.merge) []


shouldDisplayRelation : Dict TableId Table -> Relation -> Bool
shouldDisplayRelation tables relation =
    (tables |> Dict.member relation.src.table) && (tables |> Dict.member relation.ref.table)


currentVersion : Int
currentVersion =
    -- compatibility version for Project JSON, when you have breaking change, increment it and handle needed migrations
    2


downloadFilename : Project -> String
downloadFilename project =
    (project.name |> String.replace ".sql" "") ++ ".azimutt.json"


downloadContent : Project -> String
downloadContent project =
    project |> encode |> Encode.encode 2


encode : Project -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> ProjectId.encode )
        , ( "name", value.name |> ProjectName.encode )
        , ( "sources", value.sources |> Encode.list Source.encode )
        , ( "layout", value.layout |> Layout.encode )
        , ( "usedLayout", value.usedLayout |> Encode.maybe LayoutName.encode )
        , ( "layouts", value.layouts |> Encode.dict LayoutName.toString Layout.encode )
        , ( "settings", value.settings |> Encode.withDefaultDeep ProjectSettings.encode ProjectSettings.init )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        , ( "version", currentVersion |> Encode.int )
        ]


decode : Decode.Decoder Project
decode =
    Decode.map9 new
        (Decode.field "id" ProjectId.decode)
        (Decode.field "name" ProjectName.decode)
        (Decode.field "sources" (Decode.list Source.decode))
        (Decode.defaultField "layout" Layout.decode (Layout.init (Time.millisToPosix 0)))
        (Decode.maybeField "usedLayout" LayoutName.decode)
        (Decode.defaultField "layouts" (Decode.customDict LayoutName.fromString Layout.decode) Dict.empty)
        (Decode.defaultFieldDeep "settings" ProjectSettings.decode ProjectSettings.init)
        (Decode.defaultField "createdAt" Time.decode (Time.millisToPosix 0))
        (Decode.defaultField "updatedAt" Time.decode (Time.millisToPosix 0))
