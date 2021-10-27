module Models.Project exposing (Project, addSource, create, decode, defaultLayout, defaultTime, deleteSource, encode, inChecks, inIndexes, inOutRelation, inPrimaryKey, inUniques, initLayout, initProjectSettings, initTableProps, new, setSources, tablesArea, updateSource, viewportArea, viewportSize, withNullableInfo)

import Conf exposing (conf)
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Area as Area exposing (Area)
import Libs.DomInfo exposing (DomInfo)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Json.Formats exposing (decodePosix, encodePosix)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (Color)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.Position as Position exposing (Position)
import Libs.Size exposing (Size)
import Libs.String as S
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.Check exposing (Check)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.Index exposing (Index)
import Models.Project.Layout as Layout exposing (Layout)
import Models.Project.LayoutName as LayoutName exposing (LayoutName)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.ProjectName as ProjectName exposing (ProjectName)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation exposing (Relation)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)
import Models.Project.Unique exposing (Unique)
import Time


type alias Project =
    { id : ProjectId
    , name : ProjectName
    , sources : List Source
    , tables : Dict TableId Table -- computed from sources, do not update directly (see new & setSources functions)
    , relations : List Relation -- computed from sources, do not update directly (see new & setSources functions)
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
    , tables = sources |> computeTables
    , relations = sources |> computeRelations
    , layout = layout
    , usedLayout = usedLayout
    , layouts = layouts
    , settings = settings
    , createdAt = createdAt
    , updatedAt = updatedAt
    }


create : ProjectId -> ProjectName -> Source -> Project
create id name source =
    new id name [ source ] (initLayout source.createdAt) Nothing Dict.empty initProjectSettings source.createdAt source.updatedAt


setSources : (List Source -> List Source) -> Project -> Project
setSources transform project =
    transform project.sources
        |> (\sources ->
                { project
                    | sources = sources
                    , tables = sources |> computeTables
                    , relations = sources |> computeRelations
                }
           )


updateSource : SourceId -> (Source -> Source) -> Project -> Project
updateSource id transform project =
    setSources
        (List.map
            (\source ->
                if source.id == id then
                    transform source

                else
                    source
            )
        )
        project


addSource : Source -> Project -> Project
addSource source project =
    setSources (\sources -> sources ++ [ source ]) project


deleteSource : SourceId -> Project -> Project
deleteSource id project =
    setSources (List.filter (\s -> s.id /= id)) project


computeTables : List Source -> Dict TableId Table
computeTables sources =
    sources |> List.filter .enabled |> List.map .tables |> List.foldr mergeTables Dict.empty


computeRelations : List Source -> List Relation
computeRelations sources =
    sources |> List.filter .enabled |> List.map .relations |> List.foldr mergeRelations []


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
            tables |> L.zipWith (\t -> domInfos |> Dict.get (TableId.toHtmlId t.id) |> M.mapOrElse .size (Size 0 0))

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


currentVersion : Int
currentVersion =
    -- compatibility version for Project JSON, when you have breaking change, increment it and handle needed migrations
    2


encode : Project -> Value
encode value =
    E.object
        [ ( "id", value.id |> ProjectId.encode )
        , ( "name", value.name |> ProjectName.encode )
        , ( "sources", value.sources |> Encode.list Source.encode )
        , ( "layout", value.layout |> Layout.encode )
        , ( "usedLayout", value.usedLayout |> E.maybe LayoutName.encode )
        , ( "layouts", value.layouts |> Encode.dict LayoutName.toString Layout.encode )
        , ( "settings", value.settings |> E.withDefaultDeep ProjectSettings.encode initProjectSettings )
        , ( "createdAt", value.createdAt |> encodePosix )
        , ( "updatedAt", value.updatedAt |> encodePosix )
        , ( "version", currentVersion |> Encode.int )
        ]


decode : Decode.Decoder Project
decode =
    D.map9 new
        (Decode.field "id" ProjectId.decode)
        (Decode.field "name" ProjectName.decode)
        (Decode.field "sources" (Decode.list Source.decode))
        (D.defaultField "layout" Layout.decode defaultLayout)
        (D.maybeField "usedLayout" LayoutName.decode)
        (D.defaultField "layouts" (D.dict LayoutName.fromString Layout.decode) Dict.empty)
        (D.defaultFieldDeep "settings" ProjectSettings.decode initProjectSettings)
        (D.defaultField "createdAt" decodePosix defaultTime)
        (D.defaultField "updatedAt" decodePosix defaultTime)
