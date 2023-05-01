module Models.Project exposing (Project, compute, computeRelations, computeTables, computeTypes, create, decode, downloadContent, downloadFilename, duplicate, encode, new)

import Conf
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Dict as Dict
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Models.Notes as Notes exposing (Notes, NotesKey)
import Libs.String as String
import Libs.Time as Time
import Models.Organization as Organization exposing (Organization)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.CustomType as CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.Layout as Layout exposing (Layout)
import Models.Project.LayoutName as LayoutName exposing (LayoutName)
import Models.Project.Metadata as Metadata exposing (Metadata)
import Models.Project.ProjectEncodingVersion as ProjectEncodingVersion exposing (ProjectEncodingVersion)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.ProjectName as ProjectName exposing (ProjectName)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import Models.Project.ProjectSlug as ProjectSlug exposing (ProjectSlug)
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)
import Models.Project.ProjectVisibility as ProjectVisibility exposing (ProjectVisibility)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Time


type alias Project =
    { organization : Maybe Organization
    , id : ProjectId
    , slug : ProjectSlug
    , name : ProjectName
    , description : Maybe String
    , sources : List Source
    , tables : Dict TableId Table -- computed from sources, do not update directly (see compute function)
    , relations : List Relation -- computed from sources, do not update directly (see compute function)
    , types : Dict CustomTypeId CustomType -- computed from sources, do not update directly (see compute function)
    , metadata : Metadata
    , usedLayout : LayoutName
    , layouts : Dict LayoutName Layout
    , settings : ProjectSettings
    , storage : ProjectStorage
    , visibility : ProjectVisibility
    , version : ProjectEncodingVersion
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


new : Maybe Organization -> ProjectId -> ProjectSlug -> ProjectName -> Maybe String -> List Source -> Metadata -> LayoutName -> Dict LayoutName Layout -> ProjectSettings -> ProjectStorage -> ProjectVisibility -> ProjectEncodingVersion -> Time.Posix -> Time.Posix -> Project
new organization id slug name description sources metadata usedLayout layouts settings storage visibility version createdAt updatedAt =
    { organization = organization
    , id = id
    , slug = slug
    , name = name
    , description = description
    , sources = sources
    , tables = Dict.empty
    , relations = []
    , types = Dict.empty
    , metadata = metadata
    , usedLayout = usedLayout
    , layouts = layouts
    , settings = settings
    , storage = storage
    , visibility = visibility
    , version = version
    , createdAt = createdAt
    , updatedAt = updatedAt
    }
        |> compute


create : List { a | name : ProjectName } -> ProjectName -> Source -> Project
create projects name source =
    new Nothing
        ProjectId.zero
        ProjectSlug.zero
        (String.unique (projects |> List.map .name) name)
        Nothing
        [ source ]
        Dict.empty
        Conf.constants.defaultLayout
        (Dict.fromList [ ( Conf.constants.defaultLayout, Layout.empty source.createdAt ) ])
        (ProjectSettings.init (mostUsedSchema source.tables))
        ProjectStorage.Local
        ProjectVisibility.None
        ProjectEncodingVersion.current
        source.createdAt
        source.updatedAt


duplicate : List { a | name : ProjectName } -> Project -> Project
duplicate projects project =
    { project | id = ProjectId.zero, name = String.unique (projects |> List.map .name) project.name }


mostUsedSchema : Dict TableId Table -> SchemaName
mostUsedSchema table =
    table
        |> Dict.keys
        |> List.map Tuple.first
        |> List.groupBy identity
        |> Dict.map (\_ -> List.length)
        |> Dict.toList
        |> List.maximumBy (\( _, count ) -> count)
        |> Maybe.map Tuple.first
        |> Maybe.withDefault Conf.schema.empty


compute : Project -> Project
compute project =
    (project.sources |> computeTables project.settings)
        |> (\tables ->
                { project
                    | tables = tables
                    , relations = project.sources |> computeRelations tables
                    , types = project.sources |> computeTypes
                }
           )


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


computeTypes : List Source -> Dict CustomTypeId CustomType
computeTypes sources =
    sources
        |> List.filter .enabled
        |> List.map .types
        |> List.foldr (Dict.fuse CustomType.merge) Dict.empty


downloadFilename : Project -> String
downloadFilename project =
    (project.name |> String.replace ".sql" "") ++ ".azimutt.json"


downloadContent : Project -> String
downloadContent value =
    -- same as encode but without keys: `organization`, `slug`, `storage` & `visibility`
    (Encode.notNullObject
        [ ( "id", value.id |> ProjectId.encode )
        , ( "name", value.name |> ProjectName.encode )
        , ( "description", value.description |> Encode.maybe Encode.string )
        , ( "sources", value.sources |> Encode.list Source.encode )
        , ( "metadata", value.metadata |> Metadata.encode )
        , ( "usedLayout", value.usedLayout |> LayoutName.encode )
        , ( "layouts", value.layouts |> Encode.dict LayoutName.toString Layout.encode )
        , ( "settings", value.settings |> Encode.withDefaultDeep ProjectSettings.encode (ProjectSettings.init Conf.schema.empty) )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        , ( "version", ProjectEncodingVersion.current |> Encode.int )
        ]
        |> Encode.encode 2
    )
        ++ "\n"


encode : Project -> Value
encode value =
    Encode.notNullObject
        [ ( "organization", value.organization |> Encode.maybe Organization.encode )
        , ( "id", value.id |> ProjectId.encode )
        , ( "slug", value.slug |> ProjectSlug.encode )
        , ( "name", value.name |> ProjectName.encode )
        , ( "description", value.description |> Encode.maybe Encode.string )
        , ( "sources", value.sources |> Encode.list Source.encode )
        , ( "metadata", value.metadata |> Metadata.encode )
        , ( "usedLayout", value.usedLayout |> LayoutName.encode )
        , ( "layouts", value.layouts |> Encode.dict LayoutName.toString Layout.encode )
        , ( "settings", value.settings |> Encode.withDefaultDeep ProjectSettings.encode (ProjectSettings.init Conf.schema.empty) )
        , ( "storage", value.storage |> ProjectStorage.encode )
        , ( "visibility", value.visibility |> ProjectVisibility.encode )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        , ( "version", ProjectEncodingVersion.current |> Encode.int )
        ]


decode : Decode.Decoder Project
decode =
    Decode.map17 decodeProject
        (Decode.maybeField "organization" Organization.decode)
        (Decode.field "id" ProjectId.decode)
        (Decode.maybeField "slug" ProjectSlug.decode)
        (Decode.field "name" ProjectName.decode)
        (Decode.maybeField "description" Decode.string)
        (Decode.field "sources" (Decode.list Source.decode))
        -- continue to read "notes" for retro-compatibility, then merge it to `metadata` in decodeProject
        (Decode.defaultField "notes" (Decode.dict Notes.decode) Dict.empty)
        (Decode.defaultField "metadata" Metadata.decode Dict.empty)
        (Decode.defaultField "layout" Layout.decode (Layout.empty Time.zero))
        (Decode.defaultField "usedLayout" LayoutName.decode Conf.constants.defaultLayout)
        (Decode.defaultField "layouts" (Decode.customDict LayoutName.fromString Layout.decode) Dict.empty)
        (Decode.defaultFieldDeep "settings" ProjectSettings.decode (ProjectSettings.init Conf.schema.empty))
        (Decode.defaultField "storage" ProjectStorage.decode ProjectStorage.Local)
        (Decode.defaultField "visibility" ProjectVisibility.decode ProjectVisibility.None)
        (Decode.field "version" ProjectEncodingVersion.decode)
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)


decodeProject : Maybe Organization -> ProjectId -> Maybe ProjectSlug -> ProjectName -> Maybe String -> List Source -> Dict NotesKey Notes -> Metadata -> Layout -> LayoutName -> Dict LayoutName Layout -> ProjectSettings -> ProjectStorage -> ProjectVisibility -> ProjectEncodingVersion -> Time.Posix -> Time.Posix -> Project
decodeProject organization id maybeSlug name description sources notes metadata layout usedLayout layouts settings storage visibility version createdAt updatedAt =
    let
        allLayouts : Dict LayoutName Layout
        allLayouts =
            -- migrate from a default layout to only layouts
            if layout == Layout.empty Time.zero then
                layouts

            else
                layouts |> Dict.insert Conf.constants.defaultLayout layout

        slug : ProjectSlug
        slug =
            -- retro-compatibility with old projects
            maybeSlug |> Maybe.withDefault id

        fullMetadata : Metadata
        fullMetadata =
            -- migrate notes to metadata
            metadata |> mergeNotesInMetadata notes
    in
    new organization id slug name description sources fullMetadata usedLayout allLayouts settings storage visibility version createdAt updatedAt


mergeNotesInMetadata : Dict NotesKey Notes -> Metadata -> Metadata
mergeNotesInMetadata notes metadata =
    notes
        |> Dict.toList
        |> List.foldl
            (\( key, n ) meta ->
                key
                    |> parseKey
                    |> Maybe.map (\( table, column ) -> meta |> Metadata.putNotes table column (Just n))
                    |> Maybe.withDefault meta
            )
            metadata


parseKey : NotesKey -> Maybe ( TableId, Maybe ColumnPath )
parseKey key =
    case key |> String.split "." of
        schema :: table :: [] ->
            Just ( ( schema, table ), Nothing )

        schema :: table :: column :: [] ->
            Just ( ( schema, table ), Just (ColumnPath.fromString column) )

        _ ->
            Nothing
