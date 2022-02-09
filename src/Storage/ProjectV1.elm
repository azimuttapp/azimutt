module Storage.ProjectV1 exposing (CanvasPropsV1, CheckNameV1, CheckV1, ColumnIndexV1, ColumnNameV1, ColumnRefV1, ColumnTypeV1, ColumnV1, ColumnValueV1, CommentV1, FindPathSettingsV1, IndexNameV1, IndexV1, LayoutNameV1, LayoutV1, PrimaryKeyNameV1, PrimaryKeyV1, ProjectIdV1, ProjectNameV1, ProjectSettingsV1, ProjectSourceContentV1(..), ProjectSourceIdV1, ProjectSourceNameV1, ProjectSourceV1, ProjectV1, RelationNameV1, RelationV1, SampleNameV1, SchemaNameV1, SchemaV1, SourceLineV1, SourceV1, TableIdV1, TableNameV1, TablePropsV1, TableV1, UniqueNameV1, UniqueV1, decodeProject, defaultProjectSettings, upgrade)

import Array
import Conf
import Dict exposing (Dict)
import Json.Decode as Decode
import Libs.Dict as Dict
import Libs.Json.Decode as Decode
import Libs.Maybe as Maybe
import Libs.Models exposing (UID)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size
import Libs.Models.ZoomLevel exposing (ZoomLevel)
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel exposing (Nel)
import Libs.Tailwind as Tw exposing (Color)
import Libs.Time as Time
import Models.ColumnOrder exposing (ColumnOrder(..))
import Models.Project exposing (Project)
import Models.Project.CanvasProps as CanvasProps
import Models.Project.Check exposing (Check)
import Models.Project.Column exposing (Column)
import Models.Project.Comment exposing (Comment)
import Models.Project.Index exposing (Index)
import Models.Project.Layout exposing (Layout)
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.Table exposing (Table)
import Models.Project.TableProps exposing (TableProps)
import Models.Project.Unique exposing (Unique)
import Time


type alias ProjectV1 =
    { id : ProjectIdV1
    , name : ProjectNameV1
    , sources : Nel ProjectSourceV1
    , schema : SchemaV1
    , layouts : Dict LayoutNameV1 LayoutV1
    , currentLayout : Maybe LayoutNameV1
    , settings : ProjectSettingsV1
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    , fromSample : Maybe SampleNameV1
    }


type alias ProjectSourceV1 =
    -- file the project depend on, they can be refreshed over time
    { id : ProjectSourceIdV1
    , name : ProjectSourceNameV1
    , source : ProjectSourceContentV1
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


type ProjectSourceContentV1
    = LocalFileV1 String Int Time.Posix
    | RemoteFileV1 String Int


type alias SchemaV1 =
    { tables : Dict TableIdV1 TableV1, relations : List RelationV1, layout : LayoutV1 }


type alias TableV1 =
    { id : TableIdV1
    , schema : SchemaNameV1
    , name : TableNameV1
    , columns : Ned ColumnNameV1 ColumnV1
    , primaryKey : Maybe PrimaryKeyV1
    , uniques : List UniqueV1
    , indexes : List IndexV1
    , checks : List CheckV1
    , comment : Maybe CommentV1
    , sources : List SourceV1
    }


type alias ColumnV1 =
    { index : ColumnIndexV1
    , name : ColumnNameV1
    , kind : ColumnTypeV1
    , nullable : Bool
    , default : Maybe ColumnValueV1
    , comment : Maybe CommentV1
    , sources : List SourceV1
    }


type alias PrimaryKeyV1 =
    { name : PrimaryKeyNameV1, columns : Nel ColumnNameV1, sources : List SourceV1 }


type alias UniqueV1 =
    { name : UniqueNameV1, columns : Nel ColumnNameV1, definition : String, sources : List SourceV1 }


type alias IndexV1 =
    { name : IndexNameV1, columns : Nel ColumnNameV1, definition : String, sources : List SourceV1 }


type alias CheckV1 =
    { name : CheckNameV1, columns : List ColumnNameV1, predicate : String, sources : List SourceV1 }


type alias CommentV1 =
    { text : String, sources : List SourceV1 }


type alias RelationV1 =
    { name : RelationNameV1, src : ColumnRefV1, ref : ColumnRefV1, sources : List SourceV1 }


type alias ColumnRefV1 =
    { table : TableIdV1, column : ColumnNameV1 }


type alias SourceV1 =
    { id : ProjectSourceIdV1, lines : Nel SourceLineV1 }


type alias SourceLineV1 =
    { no : Int, text : String }


type alias LayoutV1 =
    { canvas : CanvasPropsV1
    , tables : List TablePropsV1
    , hiddenTables : List TablePropsV1
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


type alias CanvasPropsV1 =
    { position : Position, zoom : ZoomLevel }


type alias TablePropsV1 =
    { id : TableIdV1, position : Position, color : Color, columns : List ColumnNameV1, selected : Bool }


type alias ProjectSettingsV1 =
    { findPath : FindPathSettingsV1 }


type alias FindPathSettingsV1 =
    { maxPathLength : Int, ignoredTables : List TableIdV1, ignoredColumns : List ColumnNameV1 }


type alias ProjectIdV1 =
    UID


type alias ProjectNameV1 =
    String


type alias ProjectSourceIdV1 =
    UID


type alias ProjectSourceNameV1 =
    String


type alias TableIdV1 =
    ( SchemaNameV1, TableNameV1 )


type alias SchemaNameV1 =
    String


type alias TableNameV1 =
    String


type alias ColumnNameV1 =
    String


type alias ColumnIndexV1 =
    Int


type alias ColumnTypeV1 =
    String


type alias ColumnValueV1 =
    String


type alias PrimaryKeyNameV1 =
    String


type alias UniqueNameV1 =
    String


type alias IndexNameV1 =
    String


type alias CheckNameV1 =
    String


type alias RelationNameV1 =
    String


type alias LayoutNameV1 =
    String


type alias SampleNameV1 =
    String


stringAsTableId : String -> TableIdV1
stringAsTableId id =
    case String.split "." id of
        schema :: table :: [] ->
            ( schema, table )

        _ ->
            ( Conf.schema.default, id )


stringAsLayoutName : String -> LayoutNameV1
stringAsLayoutName name =
    name


initLayout : Time.Posix -> LayoutV1
initLayout now =
    { canvas = CanvasProps.zero, tables = [], hiddenTables = [], createdAt = now, updatedAt = now }


defaultTime : Time.Posix
defaultTime =
    Time.millisToPosix 0


defaultLayout : LayoutV1
defaultLayout =
    initLayout defaultTime


defaultProjectSettings : { findPath : FindPathSettingsV1 }
defaultProjectSettings =
    { findPath = FindPathSettingsV1 3 [] [] }



-- UPGRADE


upgrade : ProjectV1 -> Project
upgrade project =
    { id = project.id
    , name = project.name
    , sources = project.sources |> Nel.toList |> List.map (upgradeProjectSource project.schema.tables project.schema.relations project.fromSample)
    , tables = project.schema.tables |> Dict.map (\_ -> upgradeTable)
    , relations = project.schema.relations |> List.map upgradeRelation
    , layout = project.schema.layout |> upgradeLayout
    , usedLayout = project.currentLayout
    , layouts = project.layouts |> Dict.map (\_ -> upgradeLayout)
    , settings = ProjectSettings project.settings.findPath [] False "" "" SqlOrder
    , createdAt = project.createdAt
    , updatedAt = project.updatedAt
    }


upgradeLayout : LayoutV1 -> Layout
upgradeLayout layout =
    { canvas = layout.canvas
    , tables = layout.tables |> List.map upgradeTableProps
    , hiddenTables = layout.hiddenTables |> List.map upgradeTableProps
    , createdAt = layout.createdAt
    , updatedAt = layout.updatedAt
    }


upgradeTableProps : TablePropsV1 -> TableProps
upgradeTableProps props =
    { id = props.id
    , position = props.position
    , size = Size.zero
    , color = props.color
    , columns = props.columns
    , selected = props.selected
    , hiddenColumns = False
    }


upgradeProjectSource : Dict TableIdV1 TableV1 -> List RelationV1 -> Maybe SampleNameV1 -> ProjectSourceV1 -> Source
upgradeProjectSource tables relations fromSample source =
    { id = SourceId.new source.id
    , name = source.name
    , kind =
        case source.source of
            LocalFileV1 name size modified ->
                LocalFile name size modified

            RemoteFileV1 url size ->
                RemoteFile url size
    , content =
        let
            sources : Dict Int String
            sources =
                tables |> Dict.values |> List.concatMap .sources |> List.concatMap (\s -> s.lines |> Nel.toList) |> List.map (\s -> ( s.no, s.text )) |> Dict.fromList

            max : Int
            max =
                sources |> Dict.keys |> List.maximum |> Maybe.mapOrElse (\i -> i + 1) 0
        in
        List.repeat max "" |> List.indexedMap (\i a -> sources |> Dict.getOrElse i a) |> Array.fromList
    , tables = tables |> Dict.map (\_ -> upgradeTable)
    , relations = relations |> List.map upgradeRelation
    , enabled = True
    , fromSample = fromSample
    , createdAt = source.createdAt
    , updatedAt = source.updatedAt
    }


upgradeTable : TableV1 -> Table
upgradeTable table =
    { id = table.id
    , schema = table.schema
    , name = table.name
    , view = False
    , columns = table.columns |> Ned.map (\_ -> upgradeColumn)
    , primaryKey = table.primaryKey |> Maybe.map upgradePrimaryKey
    , uniques = table.uniques |> List.map upgradeUnique
    , indexes = table.indexes |> List.map upgradeIndex
    , checks = table.checks |> List.map upgradeCheck
    , comment = table.comment |> Maybe.map upgradeComment
    , origins = table.sources |> List.map upgradeSource
    }


upgradeColumn : ColumnV1 -> Column
upgradeColumn column =
    { index = column.index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment |> Maybe.map upgradeComment
    , origins = column.sources |> List.map upgradeSource
    }


upgradePrimaryKey : PrimaryKeyV1 -> PrimaryKey
upgradePrimaryKey pk =
    { name = pk.name, columns = pk.columns, origins = pk.sources |> List.map upgradeSource }


upgradeUnique : UniqueV1 -> Unique
upgradeUnique unique =
    { name = unique.name, columns = unique.columns, definition = unique.definition, origins = unique.sources |> List.map upgradeSource }


upgradeIndex : IndexV1 -> Index
upgradeIndex index =
    { name = index.name, columns = index.columns, definition = index.definition, origins = index.sources |> List.map upgradeSource }


upgradeCheck : CheckV1 -> Check
upgradeCheck check =
    { name = check.name, columns = check.columns, predicate = check.predicate, origins = check.sources |> List.map upgradeSource }


upgradeComment : CommentV1 -> Comment
upgradeComment comment =
    { text = comment.text, origins = comment.sources |> List.map upgradeSource }


upgradeRelation : RelationV1 -> Relation
upgradeRelation relation =
    Relation.new relation.name relation.src relation.ref (relation.sources |> List.map upgradeSource)


upgradeSource : SourceV1 -> Origin
upgradeSource source =
    { id = SourceId.new source.id, lines = source.lines |> Nel.toList |> List.map .no }



-- JSON


decodeProject : Decode.Decoder ProjectV1
decodeProject =
    Decode.map10 ProjectV1
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "sources" (Decode.nel decodeProjectSource))
        (Decode.field "schema" decodeSchema)
        (Decode.defaultField "layouts" (Decode.customDict stringAsLayoutName decodeLayout) Dict.empty)
        (Decode.maybeField "currentLayout" Decode.string)
        (Decode.defaultFieldDeep "settings" decodeProjectSettings defaultProjectSettings)
        (Decode.defaultField "createdAt" Time.decode defaultTime)
        (Decode.defaultField "updatedAt" Time.decode defaultTime)
        (Decode.maybeField "fromSample" Decode.string)


decodeProjectSource : Decode.Decoder ProjectSourceV1
decodeProjectSource =
    Decode.map5 ProjectSourceV1
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "source" decodeProjectSourceContent)
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)


decodeProjectSourceContent : Decode.Decoder ProjectSourceContentV1
decodeProjectSourceContent =
    Decode.matchOn "kind"
        (\kind ->
            case kind of
                "LocalFile" ->
                    Decode.map3 LocalFileV1
                        (Decode.field "name" Decode.string)
                        (Decode.field "size" Decode.int)
                        (Decode.field "lastModified" Time.decode)

                "RemoteFile" ->
                    Decode.map2 RemoteFileV1
                        (Decode.field "name" Decode.string)
                        (Decode.field "size" Decode.int)

                other ->
                    Decode.fail ("Not supported kind of ProjectSourceContent '" ++ other ++ "'")
        )


decodeSchema : Decode.Decoder SchemaV1
decodeSchema =
    Decode.map3 SchemaV1
        (Decode.field "tables" (Decode.list decodeTable) |> Decode.map (Dict.fromListMap .id))
        (Decode.field "relations" (Decode.list decodeRelation))
        (Decode.defaultField "layout" decodeLayout defaultLayout)


decodeTable : Decode.Decoder TableV1
decodeTable =
    Decode.map9 (\s t c p u i ch co so -> TableV1 ( s, t ) s t c p u i ch co so)
        (Decode.field "schema" Decode.string)
        (Decode.field "table" Decode.string)
        (Decode.field "columns" (Decode.nel decodeColumn |> Decode.map (Nel.indexedMap (\i c -> c i) >> Ned.fromNelMap .name)))
        (Decode.maybeField "primaryKey" decodePrimaryKey)
        (Decode.defaultField "uniques" (Decode.list decodeUnique) [])
        (Decode.defaultField "indexes" (Decode.list decodeIndex) [])
        (Decode.defaultField "checks" (Decode.list decodeCheck) [])
        (Decode.maybeField "comment" decodeComment)
        (Decode.defaultField "sources" (Decode.list decodeSource) [])


decodeColumn : Decode.Decoder (Int -> ColumnV1)
decodeColumn =
    Decode.map6 (\n t nu d c s -> \i -> ColumnV1 i n t nu d c s)
        (Decode.field "name" Decode.string)
        (Decode.field "type" Decode.string)
        (Decode.defaultField "nullable" Decode.bool False)
        (Decode.maybeField "default" Decode.string)
        (Decode.maybeField "comment" decodeComment)
        (Decode.defaultField "sources" (Decode.list decodeSource) [])


decodePrimaryKey : Decode.Decoder PrimaryKeyV1
decodePrimaryKey =
    Decode.map3 PrimaryKeyV1
        (Decode.field "name" Decode.string)
        (Decode.field "columns" (Decode.nel Decode.string))
        (Decode.defaultField "sources" (Decode.list decodeSource) [])


decodeUnique : Decode.Decoder UniqueV1
decodeUnique =
    Decode.map4 UniqueV1
        (Decode.field "name" Decode.string)
        (Decode.field "columns" (Decode.nel Decode.string))
        (Decode.field "definition" Decode.string)
        (Decode.defaultField "sources" (Decode.list decodeSource) [])


decodeIndex : Decode.Decoder IndexV1
decodeIndex =
    Decode.map4 IndexV1
        (Decode.field "name" Decode.string)
        (Decode.field "columns" (Decode.nel Decode.string))
        (Decode.field "definition" Decode.string)
        (Decode.defaultField "sources" (Decode.list decodeSource) [])


decodeCheck : Decode.Decoder CheckV1
decodeCheck =
    Decode.map4 CheckV1
        (Decode.field "name" Decode.string)
        (Decode.defaultField "columns" (Decode.list Decode.string) [])
        (Decode.field "predicate" Decode.string)
        (Decode.defaultField "sources" (Decode.list decodeSource) [])


decodeComment : Decode.Decoder CommentV1
decodeComment =
    Decode.map2 CommentV1
        (Decode.field "text" Decode.string)
        (Decode.defaultField "sources" (Decode.list decodeSource) [])


decodeRelation : Decode.Decoder RelationV1
decodeRelation =
    Decode.map4 RelationV1
        (Decode.field "name" Decode.string)
        (Decode.field "src" decodeColumnRef)
        (Decode.field "ref" decodeColumnRef)
        (Decode.defaultField "sources" (Decode.list decodeSource) [])


decodeColumnRef : Decode.Decoder ColumnRefV1
decodeColumnRef =
    Decode.map2 ColumnRefV1
        (Decode.field "table" decodeTableId)
        (Decode.field "column" Decode.string)


decodeSource : Decode.Decoder SourceV1
decodeSource =
    Decode.map2 SourceV1
        (Decode.field "id" Decode.string)
        (Decode.field "lines" (Decode.nel decodeSourceLine))


decodeSourceLine : Decode.Decoder SourceLineV1
decodeSourceLine =
    Decode.map2 SourceLineV1
        (Decode.field "no" Decode.int)
        (Decode.field "text" Decode.string)


decodeLayout : Decode.Decoder LayoutV1
decodeLayout =
    Decode.map5 LayoutV1
        (Decode.field "canvas" CanvasProps.decode)
        (Decode.field "tables" (Decode.list decodeTableProps))
        (Decode.defaultField "hiddenTables" (Decode.list decodeTableProps) [])
        (Decode.field "createdAt" Time.decode)
        (Decode.field "updatedAt" Time.decode)


decodeTableProps : Decode.Decoder TablePropsV1
decodeTableProps =
    Decode.map5 TablePropsV1
        (Decode.field "id" decodeTableId)
        (Decode.field "position" Position.decode)
        (Decode.field "color" Tw.decodeColor)
        (Decode.defaultField "columns" (Decode.list Decode.string) [])
        (Decode.defaultField "selected" Decode.bool False)


decodeProjectSettings : ProjectSettingsV1 -> Decode.Decoder ProjectSettingsV1
decodeProjectSettings default =
    Decode.map ProjectSettingsV1
        (Decode.defaultFieldDeep "findPath" decodeFindPathSettings default.findPath)


decodeFindPathSettings : FindPathSettingsV1 -> Decode.Decoder FindPathSettingsV1
decodeFindPathSettings default =
    Decode.map3 FindPathSettingsV1
        (Decode.defaultField "maxPathLength" Decode.int default.maxPathLength)
        (Decode.defaultField "ignoredTables" (Decode.list decodeTableId) default.ignoredTables)
        (Decode.defaultField "ignoredColumns" (Decode.list Decode.string) default.ignoredColumns)


decodeTableId : Decode.Decoder TableIdV1
decodeTableId =
    Decode.string |> Decode.map stringAsTableId
