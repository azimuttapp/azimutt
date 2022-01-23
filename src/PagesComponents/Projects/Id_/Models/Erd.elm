module PagesComponents.Projects.Id_.Models.Erd exposing (Erd, create, createLayout, getColumn, getColumnProps, initTable, isShown, unpack, unpackLayout)

import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Ned as Ned
import Models.Project exposing (Project)
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Layout exposing (Layout)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation exposing (Relation)
import Models.Project.Source exposing (Source)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Projects.Id_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import PagesComponents.Projects.Id_.Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Time


type alias Erd =
    { project : ProjectInfo
    , canvas : CanvasProps
    , tables : Dict TableId ErdTable
    , relations : List ErdRelation
    , relationsByTable : Dict TableId (List Relation)
    , tableProps : Dict TableId ErdTableProps
    , shownTables : List TableId
    , usedLayout : Maybe LayoutName
    , layouts : Dict LayoutName Layout
    , sources : List Source
    , settings : ProjectSettings
    , otherProjects : List ProjectInfo
    }


create : List Project -> Project -> Erd
create allProjects project =
    let
        relationsByTable : Dict TableId (List Relation)
        relationsByTable =
            project.relations
                |> List.foldr
                    (\rel dict ->
                        if rel.src.table == rel.ref.table then
                            dict |> Dict.update rel.src.table (Maybe.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)

                        else
                            dict
                                |> Dict.update rel.src.table (Maybe.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)
                                |> Dict.update rel.ref.table (Maybe.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)
                    )
                    Dict.empty

        ( canvas, tableProps, shownTables ) =
            createLayout relationsByTable project.layout
    in
    { project = ProjectInfo.create project
    , canvas = canvas
    , tables = project.tables |> Dict.map (\id -> ErdTable.create project.tables (relationsByTable |> Dict.getOrElse id []))
    , relations = project.relations |> List.map (ErdRelation.create project.tables)
    , relationsByTable = relationsByTable
    , tableProps = tableProps
    , shownTables = shownTables
    , usedLayout = project.usedLayout
    , layouts = project.layouts
    , sources = project.sources
    , settings = project.settings
    , otherProjects = allProjects |> List.filter (\p -> p.id /= project.id) |> List.map ProjectInfo.create |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt))
    }


unpack : Erd -> Project
unpack erd =
    let
        ( layoutCreatedAt, layoutUpdatedAt ) =
            erd.usedLayout |> Maybe.andThen (\l -> erd.layouts |> Dict.get l) |> Maybe.mapOrElse (\l -> ( l.createdAt, l.updatedAt )) ( Time.millisToPosix 0, Time.millisToPosix 0 )
    in
    { id = erd.project.id
    , name = erd.project.name
    , sources = erd.sources
    , tables = erd.tables |> Dict.map (\_ -> ErdTable.unpack)
    , relations = erd.relations |> List.map ErdRelation.unpack
    , layout = unpackLayout erd.canvas erd.tableProps erd.shownTables layoutCreatedAt layoutUpdatedAt
    , usedLayout = erd.usedLayout
    , layouts = erd.layouts
    , settings = erd.settings
    , createdAt = erd.project.createdAt
    , updatedAt = erd.project.updatedAt
    }


createLayout : Dict TableId (List Relation) -> Layout -> ( CanvasProps, Dict TableId ErdTableProps, List TableId )
createLayout relationsByTable layout =
    let
        layoutProps : List TableProps
        layoutProps =
            layout.tables ++ layout.hiddenTables
    in
    ( layout.canvas
    , layoutProps |> List.map (\p -> ( p.id, ErdTableProps.create (relationsByTable |> Dict.getOrElse p.id []) (layout.tables |> List.map .id) p )) |> Dict.fromList
    , layout.tables |> List.map .id
    )


unpackLayout : CanvasProps -> Dict TableId ErdTableProps -> List TableId -> Time.Posix -> Time.Posix -> Layout
unpackLayout canvas tableProps shownTables createdAt updatedAt =
    let
        ( tables, hiddenTables ) =
            tableProps |> Dict.keys |> List.partition (\id -> shownTables |> List.member id)
    in
    { canvas = canvas
    , tables = tables |> List.filterMap (ErdTableProps.unpack tableProps)
    , hiddenTables = hiddenTables |> List.filterMap (ErdTableProps.unpack tableProps)
    , createdAt = createdAt
    , updatedAt = updatedAt
    }


getColumn : TableId -> ColumnName -> Erd -> Maybe ErdColumn
getColumn table column erd =
    erd.tables |> Dict.get table |> Maybe.andThen (\t -> t.columns |> Ned.get column)


getColumnProps : TableId -> ColumnName -> Erd -> Maybe ErdColumnProps
getColumnProps table column erd =
    erd.tableProps |> Dict.get table |> Maybe.andThen (\t -> t.columnProps |> Dict.get column)


isShown : TableId -> Erd -> Bool
isShown table erd =
    erd.shownTables |> List.member table


initTable : ErdTable -> Erd -> ErdTableProps
initTable table erd =
    ErdTableProps.init erd.settings erd.relations erd.shownTables table
