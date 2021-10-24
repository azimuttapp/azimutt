module Models.Project exposing (CanvasProps, Check, CheckName, Column, ColumnIndex, ColumnName, ColumnRef, ColumnRefFull, ColumnType, ColumnValue, Comment, FindPath, FindPathPath, FindPathResult, FindPathSettings, FindPathState(..), FindPathStep, FindPathStepDir(..), Index, IndexName, Layout, LayoutName, Origin, PrimaryKey, PrimaryKeyName, Project, ProjectId, ProjectName, ProjectSettings, Relation, RelationFull, RelationName, SampleName, SchemaName, Source, SourceId, SourceInfo, SourceKind(..), SourceLine, SourceName, Table, TableId, TableName, TableProps, Unique, UniqueName, addSource, buildProject, defaultLayout, defaultTime, extractPath, htmlIdAsTableId, htmlIdDecode, htmlIdEncode, inChecks, inIndexes, inOutRelation, inPrimaryKey, inUniques, initLayout, initProject, initProjectSettings, initTableProps, layoutNameAsString, mergeRelations, mergeTables, parseTableId, showColumnRef, showTableId, showTableName, stringAsLayoutName, stringAsTableId, tableIdAsHtmlId, tableIdAsString, tablesArea, viewportArea, viewportSize, withNullableInfo)

import Array exposing (Array)
import Conf exposing (conf)
import Dict exposing (Dict)
import Libs.Area as Area exposing (Area)
import Libs.DomInfo exposing (DomInfo)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (Color, FileLineIndex, FileModified, FileName, FileSize, FileUrl, HtmlId, UID, ZoomLevel)
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel exposing (Nel)
import Libs.Position as Position exposing (Position)
import Libs.Size exposing (Size)
import Libs.String as S
import Time
import Url exposing (percentDecode, percentEncode)


type alias Project =
    { id : ProjectId
    , name : ProjectName
    , sources : List Source
    , tables : Dict TableId Table
    , relations : List Relation
    , layout : Layout
    , usedLayout : Maybe LayoutName
    , layouts : Dict LayoutName Layout
    , settings : ProjectSettings
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


type alias Source =
    { id : SourceId
    , name : SourceName
    , kind : SourceKind
    , content : Array SourceLine
    , tables : Dict TableId Table
    , relations : List Relation
    , enabled : Bool
    , fromSample : Maybe SampleName
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


type alias SourceInfo =
    { id : SourceId
    , name : SourceName
    , kind : SourceKind
    , enabled : Bool
    , fromSample : Maybe SampleName
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


type SourceKind
    = LocalFile FileName FileSize FileModified
    | RemoteFile FileUrl FileSize


type alias Table =
    { id : TableId
    , schema : SchemaName
    , name : TableName
    , columns : Ned ColumnName Column
    , primaryKey : Maybe PrimaryKey
    , uniques : List Unique
    , indexes : List Index
    , checks : List Check
    , comment : Maybe Comment
    , origins : List Origin
    }


type alias Column =
    { index : ColumnIndex
    , name : ColumnName
    , kind : ColumnType
    , nullable : Bool
    , default : Maybe ColumnValue
    , comment : Maybe Comment
    , origins : List Origin
    }


type alias PrimaryKey =
    { name : PrimaryKeyName, columns : Nel ColumnName, origins : List Origin }


type alias Unique =
    { name : UniqueName, columns : Nel ColumnName, definition : String, origins : List Origin }


type alias Index =
    { name : IndexName, columns : Nel ColumnName, definition : String, origins : List Origin }


type alias Check =
    { name : CheckName, columns : List ColumnName, predicate : String, origins : List Origin }


type alias Comment =
    { text : String, origins : List Origin }


type alias Relation =
    { name : RelationName, src : ColumnRef, ref : ColumnRef, origins : List Origin }


type alias ColumnRef =
    { table : TableId, column : ColumnName }


type alias RelationFull =
    { name : RelationName, src : ColumnRefFull, ref : ColumnRefFull, origins : List Origin }


type alias ColumnRefFull =
    { ref : ColumnRef, table : Table, column : Column, props : Maybe ( TableProps, Int, Size ) }


type alias Origin =
    { id : SourceId, lines : List FileLineIndex }


type alias Layout =
    { canvas : CanvasProps
    , tables : List TableProps
    , hiddenTables : List TableProps
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


type alias CanvasProps =
    { position : Position, zoom : ZoomLevel }


type alias TableProps =
    { id : TableId, position : Position, color : Color, columns : List ColumnName, selected : Bool }


type alias ProjectSettings =
    { findPath : FindPathSettings }


type alias FindPath =
    { from : Maybe TableId
    , to : Maybe TableId
    , result : FindPathState
    }


type FindPathState
    = Empty
    | Searching
    | Found FindPathResult


type alias FindPathResult =
    { from : TableId
    , to : TableId
    , paths : List FindPathPath
    , settings : FindPathSettings
    }


type alias FindPathPath =
    Nel FindPathStep


type alias FindPathStep =
    { relation : Relation, direction : FindPathStepDir }


type FindPathStepDir
    = Right
    | Left


type alias FindPathSettings =
    { maxPathLength : Int, ignoredTables : List TableId, ignoredColumns : List ColumnName }


type alias ProjectId =
    UID


type alias ProjectName =
    String


type alias SourceId =
    UID


type alias SourceName =
    String


type alias SourceLine =
    String


type alias TableId =
    ( SchemaName, TableName )


type alias SchemaName =
    String


type alias TableName =
    String


type alias ColumnName =
    String


type alias ColumnIndex =
    Int


type alias ColumnType =
    String


type alias ColumnValue =
    String


type alias PrimaryKeyName =
    String


type alias UniqueName =
    String


type alias IndexName =
    String


type alias CheckName =
    String


type alias RelationName =
    String


type alias LayoutName =
    String


type alias SampleName =
    String


initProject : ProjectId -> ProjectName -> Source -> Project
initProject id name source =
    buildProject id name [ source ] (initLayout source.createdAt) Nothing Dict.empty initProjectSettings source.createdAt source.updatedAt


buildProject : ProjectId -> ProjectName -> List Source -> Layout -> Maybe LayoutName -> Dict LayoutName Layout -> ProjectSettings -> Time.Posix -> Time.Posix -> Project
buildProject id name sources layout usedLayout layouts settings createdAt updatedAt =
    { id = id
    , name = name
    , sources = sources
    , tables = sources |> List.filter .enabled |> List.map .tables |> List.foldr mergeTables Dict.empty
    , relations = sources |> List.filter .enabled |> List.map .relations |> List.foldr mergeRelations []
    , layout = layout
    , usedLayout = usedLayout
    , layouts = layouts
    , settings = settings
    , createdAt = createdAt
    , updatedAt = updatedAt
    }


addSource : Source -> Project -> Project
addSource source project =
    { project
        | sources = project.sources ++ [ source ]
        , tables = mergeTables project.tables source.tables
        , relations = mergeRelations project.relations source.relations
        , updatedAt = source.updatedAt
    }


mergeTables : Dict TableId Table -> Dict TableId Table -> Dict TableId Table
mergeTables tables1 tables2 =
    Dict.merge Dict.insert (\id t1 t2 acc -> Dict.insert id (mergeTable t1 t2) acc) Dict.insert tables1 tables2 Dict.empty


mergeTable : Table -> Table -> Table
mergeTable t1 t2 =
    { t1 | origins = t1.origins ++ t2.origins }


mergeRelations : List Relation -> List Relation -> List Relation
mergeRelations relations1 relations2 =
    (relations1 |> List.map (\r1 -> relations2 |> L.find (sameRelation r1) |> M.mapOrElse (mergeRelation r1) r1))
        ++ (relations2 |> L.filterNot (\r2 -> relations1 |> List.any (sameRelation r2)))


sameRelation : Relation -> Relation -> Bool
sameRelation r1 r2 =
    r1.name == r2.name


mergeRelation : Relation -> Relation -> Relation
mergeRelation r1 r2 =
    { r1 | origins = r1.origins ++ r2.origins }


htmlIdEncode : String -> HtmlId
htmlIdEncode text =
    text |> percentEncode


htmlIdDecode : String -> HtmlId
htmlIdDecode text =
    text |> percentDecode |> Maybe.withDefault text


tableIdAsHtmlId : TableId -> HtmlId
tableIdAsHtmlId ( schema, table ) =
    "table-" ++ schema ++ "-" ++ (table |> htmlIdEncode)


htmlIdAsTableId : HtmlId -> TableId
htmlIdAsTableId id =
    case String.split "-" id of
        "table" :: schema :: table :: [] ->
            ( schema, table |> htmlIdDecode )

        _ ->
            ( conf.default.schema, id )


tableIdAsString : TableId -> String
tableIdAsString ( schema, table ) =
    schema ++ "." ++ table


stringAsTableId : String -> TableId
stringAsTableId id =
    case String.split "." id of
        schema :: table :: [] ->
            ( schema, table )

        _ ->
            ( conf.default.schema, id )


layoutNameAsString : LayoutName -> String
layoutNameAsString name =
    name


stringAsLayoutName : String -> LayoutName
stringAsLayoutName name =
    name


showTableName : SchemaName -> TableName -> String
showTableName schema table =
    if schema == conf.default.schema then
        table

    else
        schema ++ "." ++ table


showTableId : TableId -> String
showTableId ( schema, table ) =
    showTableName schema table


parseTableId : String -> TableId
parseTableId tableId =
    case tableId |> String.split "." of
        table :: [] ->
            ( conf.default.schema, table )

        schema :: table :: [] ->
            ( schema, table )

        _ ->
            ( conf.default.schema, tableId )


showColumnRef : ColumnRef -> String
showColumnRef ref =
    showTableId ref.table ++ "." ++ ref.column


extractPath : SourceKind -> String
extractPath sourceContent =
    case sourceContent of
        LocalFile path _ _ ->
            path

        RemoteFile url _ ->
            url


inPrimaryKey : Table -> ColumnName -> Maybe PrimaryKey
inPrimaryKey table column =
    table.primaryKey |> M.filter (\{ columns } -> columns |> Nel.toList |> hasColumn column)


inUniques : Table -> ColumnName -> List Unique
inUniques table column =
    table.uniques |> List.filter (\u -> u.columns |> Nel.toList |> hasColumn column)


inIndexes : Table -> ColumnName -> List Index
inIndexes table column =
    table.indexes |> List.filter (\i -> i.columns |> Nel.toList |> hasColumn column)


inChecks : Table -> ColumnName -> List Check
inChecks table column =
    table.checks |> List.filter (\i -> i.columns |> hasColumn column)


hasColumn : ColumnName -> List ColumnName -> Bool
hasColumn column columns =
    columns |> List.any (\c -> c == column)


inOutRelation : List Relation -> ColumnName -> List Relation
inOutRelation tableOutRelations column =
    tableOutRelations |> List.filter (\r -> r.src.column == column)


withNullableInfo : Bool -> String -> String
withNullableInfo nullable text =
    if nullable then
        text ++ "?"

    else
        text


viewportSize : Dict HtmlId DomInfo -> Maybe Size
viewportSize domInfos =
    domInfos |> Dict.get conf.ids.erd |> Maybe.map .size


viewportArea : Size -> CanvasProps -> Area
viewportArea size canvas =
    Area (canvas.position |> Position.negate) size |> Area.div canvas.zoom


tablesArea : Dict HtmlId DomInfo -> List TableProps -> Area
tablesArea domInfos tables =
    let
        positions : List ( TableProps, Size )
        positions =
            tables |> L.zipWith (\t -> domInfos |> Dict.get (tableIdAsHtmlId t.id) |> M.mapOrElse .size (Size 0 0))

        left : Float
        left =
            positions |> List.map (\( t, _ ) -> t.position.left) |> List.minimum |> Maybe.withDefault 0

        top : Float
        top =
            positions |> List.map (\( t, _ ) -> t.position.top) |> List.minimum |> Maybe.withDefault 0

        right : Float
        right =
            positions |> List.map (\( t, s ) -> t.position.left + s.width) |> List.maximum |> Maybe.withDefault 0

        bottom : Float
        bottom =
            positions |> List.map (\( t, s ) -> t.position.top + s.height) |> List.maximum |> Maybe.withDefault 0
    in
    Area (Position left top) (Size (right - left) (bottom - top))


initLayout : Time.Posix -> Layout
initLayout now =
    { canvas = CanvasProps (Position 0 0) 1, tables = [], hiddenTables = [], createdAt = now, updatedAt = now }


initTableProps : Table -> TableProps
initTableProps table =
    { id = table.id
    , position = Position 0 0
    , color = computeColor table.id
    , selected = False
    , columns = table.columns |> Ned.values |> Nel.toList |> List.sortBy .index |> List.map .name
    }


computeColor : TableId -> Color
computeColor ( _, table ) =
    S.wordSplit table
        |> List.head
        |> Maybe.map S.hashCode
        |> Maybe.map (modBy (List.length conf.colors))
        |> Maybe.andThen (\index -> conf.colors |> L.get index)
        |> Maybe.withDefault conf.default.color


initProjectSettings : { findPath : FindPathSettings }
initProjectSettings =
    { findPath = FindPathSettings 3 [] [] }


defaultTime : Time.Posix
defaultTime =
    Time.millisToPosix 0


defaultLayout : Layout
defaultLayout =
    initLayout defaultTime
