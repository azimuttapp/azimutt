module Models.Project exposing (Project, create, decode, downloadContent, downloadFilename, duplicate, encode, relations, tables, types)

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
import Models.Project.CustomType exposing (CustomType)
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
import Models.Project.Relation exposing (Relation)
import Models.Project.RelationId exposing (RelationId)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Time


type alias Project =
    { organization : Maybe Organization
    , id : ProjectId
    , slug : ProjectSlug
    , name : ProjectName
    , description : Maybe String
    , sources : List Source
    , ignoredRelations : Dict TableId (List ColumnPath)
    , metadata : Metadata
    , layouts : Dict LayoutName Layout
    , tableRowsSeq : Int
    , settings : ProjectSettings
    , storage : ProjectStorage
    , visibility : ProjectVisibility
    , version : ProjectEncodingVersion
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


create : List { a | name : ProjectName } -> ProjectName -> Source -> Project
create projects name source =
    Project
        Nothing
        ProjectId.zero
        ProjectSlug.zero
        (String.unique (projects |> List.map .name) name)
        Nothing
        [ source ]
        Dict.empty
        Dict.empty
        (Dict.fromList [ ( Conf.constants.defaultLayout, Layout.empty source.createdAt ) ])
        1
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



-- should be the same as `legacyComputeStats` in libs/models/src/legacy/legacyProject.ts


tables : Project -> Dict TableId (List Table)
tables p =
    p.sources |> List.concatMap (\s -> s.tables |> Dict.values) |> List.groupBy .id


relations : Project -> Dict RelationId (List Relation)
relations p =
    p.sources |> List.concatMap .relations |> List.groupBy .id


types : Project -> Dict CustomTypeId (List CustomType)
types p =
    p.sources |> List.concatMap (\s -> s.types |> Dict.values) |> List.groupBy .id


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
        , ( "ignoredRelations", value.ignoredRelations |> Encode.withDefault (Encode.dict TableId.toString (Encode.list ColumnPath.encode)) Dict.empty )
        , ( "metadata", value.metadata |> Metadata.encode )
        , ( "layouts", value.layouts |> Encode.dict LayoutName.toString Layout.encode )
        , ( "tableRowsSeq", value.tableRowsSeq |> Encode.withDefault Encode.int 1 )
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
        , ( "ignoredRelations", value.ignoredRelations |> Encode.withDefault (Encode.dict TableId.toString (Encode.list ColumnPath.encode)) Dict.empty )
        , ( "metadata", value.metadata |> Metadata.encode )
        , ( "layouts", value.layouts |> Encode.dict LayoutName.toString Layout.encode )
        , ( "tableRowsSeq", value.tableRowsSeq |> Encode.withDefault Encode.int 1 )
        , ( "settings", value.settings |> Encode.withDefaultDeep ProjectSettings.encode (ProjectSettings.init Conf.schema.empty) )
        , ( "storage", value.storage |> ProjectStorage.encode )
        , ( "visibility", value.visibility |> ProjectVisibility.encode )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        , ( "version", ProjectEncodingVersion.current |> Encode.int )
        ]


decode : Decode.Decoder Project
decode =
    Decode.map18 decodeProject
        (Decode.maybeField "organization" Organization.decode)
        (Decode.field "id" ProjectId.decode)
        (Decode.maybeField "slug" ProjectSlug.decode)
        (Decode.field "name" ProjectName.decode)
        (Decode.maybeField "description" Decode.string)
        (Decode.field "sources" (Decode.list Source.decode))
        (Decode.defaultField "ignoredRelations" (Decode.dict (Decode.list ColumnPath.decode) |> Decode.map (Dict.mapKeys TableId.parse)) Dict.empty)
        -- continue to read "notes" for retro-compatibility, then merge it to `metadata` in decodeProject
        (Decode.defaultField "notes" (Decode.dict Notes.decode) Dict.empty)
        (Decode.defaultField "metadata" Metadata.decode Dict.empty)
        (Decode.defaultField "layout" Layout.decode (Layout.empty Time.zero))
        (Decode.defaultField "layouts" (Decode.customDict LayoutName.fromString Layout.decode) Dict.empty)
        (Decode.defaultField "tableRowsSeq" Decode.int 1)
        (Decode.defaultFieldDeep "settings" ProjectSettings.decode (ProjectSettings.init Conf.schema.empty))
        (Decode.defaultField "storage" ProjectStorage.decode ProjectStorage.Local)
        (Decode.defaultField "visibility" ProjectVisibility.decode ProjectVisibility.None)
        (Decode.field "version" ProjectEncodingVersion.decode)
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)


decodeProject : Maybe Organization -> ProjectId -> Maybe ProjectSlug -> ProjectName -> Maybe String -> List Source -> Dict TableId (List ColumnPath) -> Dict NotesKey Notes -> Metadata -> Layout -> Dict LayoutName Layout -> Int -> ProjectSettings -> ProjectStorage -> ProjectVisibility -> ProjectEncodingVersion -> Time.Posix -> Time.Posix -> Project
decodeProject organization id maybeSlug name description sources ignoredRelations notes metadata layout layouts tableRowsSeq settings storage visibility version createdAt updatedAt =
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
    Project organization id slug name description sources ignoredRelations fullMetadata allLayouts tableRowsSeq settings storage visibility version createdAt updatedAt


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
