module Models.Project exposing (Project, addSource, addUserSource, compute, create, decode, deleteSource, encode, new, setSources, tablesArea, updateSource, viewportArea, viewportSize)

import Conf
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Area as Area exposing (Area)
import Libs.Dict as D
import Libs.DomInfo exposing (DomInfo)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Libs.Time as Time
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.Layout as Layout exposing (Layout)
import Models.Project.LayoutName as LayoutName exposing (LayoutName)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.ProjectName as ProjectName exposing (ProjectName)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)
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


setSources : (List Source -> List Source) -> Project -> Project
setSources transform project =
    transform project.sources |> (\sources -> { project | sources = sources } |> compute)


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


addUserSource : SourceId -> Dict TableId Table -> List Relation -> Time.Posix -> Project -> Project
addUserSource id tables relations now project =
    setSources (\sources -> sources ++ [ Source.user id tables relations now ]) project


deleteSource : SourceId -> Project -> Project
deleteSource id project =
    setSources (List.filter (\s -> s.id /= id)) project


compute : Project -> Project
compute project =
    { project
        | tables = project.sources |> computeTables project.settings
        , relations = project.sources |> computeRelations
    }


computeTables : ProjectSettings -> List Source -> Dict TableId Table
computeTables settings sources =
    sources
        |> List.filter .enabled
        |> List.map (\s -> s.tables |> Dict.filter (\_ -> shouldDisplayTable settings))
        |> List.foldr (D.merge Table.merge) Dict.empty


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
            table |> ProjectSettings.isTableRemoved settings.removedTables
    in
    not isSchemaRemoved && not isViewRemoved && not isTableRemoved


computeRelations : List Source -> List Relation
computeRelations sources =
    sources |> List.filter .enabled |> List.map .relations |> List.foldr (L.merge .id Relation.merge) []


viewportSize : Dict HtmlId DomInfo -> Maybe Size
viewportSize domInfos =
    -- TODO remove, used to inject into viewportArea most of the time
    domInfos |> Dict.get Conf.ids.erd |> Maybe.map .size


viewportArea : Size -> CanvasProps -> Area
viewportArea size canvas =
    -- TODO use CanvasProps.viewport instead
    Area (canvas.position |> Position.negate) size |> Area.div canvas.zoom


tablesArea : Dict HtmlId DomInfo -> List TableProps -> Area
tablesArea domInfos tables =
    let
        positions : List ( TableProps, Size )
        positions =
            tables |> L.zipWith (\t -> domInfos |> Dict.get (TableId.toHtmlId t.id) |> M.mapOrElse .size Size.zero)

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
        , ( "settings", value.settings |> E.withDefaultDeep ProjectSettings.encode ProjectSettings.init )
        , ( "createdAt", value.createdAt |> Time.encode )
        , ( "updatedAt", value.updatedAt |> Time.encode )
        , ( "version", currentVersion |> Encode.int )
        ]


decode : Decode.Decoder Project
decode =
    D.map9 new
        (Decode.field "id" ProjectId.decode)
        (Decode.field "name" ProjectName.decode)
        (Decode.field "sources" (Decode.list Source.decode))
        (D.defaultField "layout" Layout.decode (Layout.init (Time.millisToPosix 0)))
        (D.maybeField "usedLayout" LayoutName.decode)
        (D.defaultField "layouts" (D.dict LayoutName.fromString Layout.decode) Dict.empty)
        (D.defaultFieldDeep "settings" ProjectSettings.decode ProjectSettings.init)
        (D.defaultField "createdAt" Time.decode (Time.millisToPosix 0))
        (D.defaultField "updatedAt" Time.decode (Time.millisToPosix 0))
