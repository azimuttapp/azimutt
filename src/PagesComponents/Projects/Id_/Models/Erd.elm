module PagesComponents.Projects.Id_.Models.Erd exposing (Erd, canResetCanvas, create, createLayout, getColumn, getColumnProps, isShown, mapSettings, mapSource, mapSources, setSettings, setSources, unpack, unpackLayout)

import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Models.Project as Project exposing (Project)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Layout exposing (Layout)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectSettings exposing (ProjectSettings)
import Models.Project.ProjectStorage exposing (ProjectStorage)
import Models.Project.Relation exposing (Relation)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Projects.Id_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
import PagesComponents.Projects.Id_.Models.Notes exposing (Notes, NotesKey)
import PagesComponents.Projects.Id_.Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Random
import Time


type alias Erd =
    { seed : Random.Seed
    , project : ProjectInfo
    , canvas : CanvasProps
    , tables : Dict TableId ErdTable
    , relations : List ErdRelation
    , notes : Dict NotesKey Notes
    , relationsByTable : Dict TableId (List Relation)
    , tableProps : Dict TableId ErdTableProps
    , shownTables : List TableId
    , usedLayout : Maybe LayoutName
    , layouts : Dict LayoutName Layout
    , sources : List Source
    , settings : ProjectSettings
    , storage : ProjectStorage
    }


create : Random.Seed -> Project -> Erd
create seed project =
    let
        relationsByTable : Dict TableId (List Relation)
        relationsByTable =
            buildRelationsByTable project.relations

        ( canvas, tableProps, shownTables ) =
            createLayout relationsByTable project.notes project.layout
    in
    { seed = seed
    , project = ProjectInfo.create project
    , canvas = canvas
    , tables = project.tables |> Dict.map (\id -> ErdTable.create project.tables (relationsByTable |> Dict.getOrElse id []))
    , relations = project.relations |> List.map (ErdRelation.create project.tables)
    , notes = project.notes
    , relationsByTable = relationsByTable
    , tableProps = tableProps
    , shownTables = shownTables
    , usedLayout = project.usedLayout
    , layouts = project.layouts
    , sources = project.sources
    , settings = project.settings
    , storage = project.storage
    }
        |> computeSchema


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
    , notes = erd.notes
    , layout = unpackLayout erd.canvas erd.tableProps erd.shownTables layoutCreatedAt layoutUpdatedAt
    , usedLayout = erd.usedLayout
    , layouts = erd.layouts
    , settings = erd.settings
    , storage = erd.storage
    , createdAt = erd.project.createdAt
    , updatedAt = erd.project.updatedAt
    }


createLayout : Dict TableId (List Relation) -> Dict NotesKey Notes -> Layout -> ( CanvasProps, Dict TableId ErdTableProps, List TableId )
createLayout relationsByTable notes layout =
    let
        layoutProps : List TableProps
        layoutProps =
            layout.tables ++ layout.hiddenTables
    in
    ( layout.canvas
    , layoutProps |> List.map (\p -> ( p.id, ErdTableProps.create (relationsByTable |> Dict.getOrElse p.id []) (layout.tables |> List.map .id) Nothing notes p )) |> Dict.fromList
    , layout.tables |> List.map .id
    )


unpackLayout : CanvasProps -> Dict TableId ErdTableProps -> List TableId -> Time.Posix -> Time.Posix -> Layout
unpackLayout canvas tableProps shownTables createdAt updatedAt =
    let
        ( tables, hiddenTables ) =
            tableProps |> Dict.keys |> List.partition (\id -> shownTables |> List.member id)
    in
    { canvas = canvas
    , tables = tables |> List.filterMap (\id -> tableProps |> Dict.get id |> Maybe.map ErdTableProps.unpack)
    , hiddenTables = hiddenTables |> List.filterMap (\id -> tableProps |> Dict.get id |> Maybe.map ErdTableProps.unpack)
    , createdAt = createdAt
    , updatedAt = updatedAt
    }


canResetCanvas : Erd -> Bool
canResetCanvas erd =
    erd.canvas /= CanvasProps.zero || Dict.nonEmpty erd.tableProps || erd.usedLayout /= Nothing


getColumn : TableId -> ColumnName -> Erd -> Maybe ErdColumn
getColumn table column erd =
    erd.tables |> Dict.get table |> Maybe.andThen (\t -> t.columns |> Dict.get column)


getColumnProps : TableId -> ColumnName -> Erd -> Maybe ErdColumnProps
getColumnProps table column erd =
    erd.tableProps |> Dict.get table |> Maybe.andThen (\t -> t.columnProps |> Dict.get column)


isShown : TableId -> Erd -> Bool
isShown table erd =
    erd.shownTables |> List.member table


computeSchema : Erd -> Erd
computeSchema erd =
    let
        tables : Dict TableId Table
        tables =
            erd.sources |> Project.computeTables erd.settings

        relations : List Relation
        relations =
            erd.sources |> Project.computeRelations tables

        relationsByTable : Dict TableId (List Relation)
        relationsByTable =
            buildRelationsByTable relations

        tableProps : Dict TableId ErdTableProps
        tableProps =
            erd.tableProps |> Dict.map (\_ p -> { p | relatedTables = ErdTableProps.buildRelatedTables (relationsByTable |> Dict.getOrElse p.id []) erd.shownTables p.id })
    in
    { erd
        | tables = tables |> Dict.map (\id -> ErdTable.create tables (relationsByTable |> Dict.getOrElse id []))
        , relations = relations |> List.map (ErdRelation.create tables)
        , relationsByTable = relationsByTable
        , tableProps = tableProps
    }


buildRelationsByTable : List Relation -> Dict TableId (List Relation)
buildRelationsByTable relations =
    relations
        |> List.foldr
            (\rel dict ->
                if rel.src.table == rel.ref.table then
                    dict |> Dict.update rel.src.table (Maybe.mapOrElse (\rels -> rel :: rels) [ rel ] >> Just)

                else
                    dict
                        |> Dict.update rel.src.table (Maybe.mapOrElse (\rels -> rel :: rels) [ rel ] >> Just)
                        |> Dict.update rel.ref.table (Maybe.mapOrElse (\rels -> rel :: rels) [ rel ] >> Just)
            )
            Dict.empty


setSources : List Source -> Erd -> Erd
setSources sources erd =
    if erd.sources == sources then
        erd

    else
        { erd | sources = sources } |> computeSchema


mapSources : (List Source -> List Source) -> Erd -> Erd
mapSources transform erd =
    setSources (transform erd.sources) erd


mapSource : SourceId -> (Source -> Source) -> Erd -> Erd
mapSource id transform erd =
    setSources (List.updateBy .id id transform erd.sources) erd


setSettings : ProjectSettings -> Erd -> Erd
setSettings settings erd =
    if erd.settings == settings then
        erd

    else
        { erd | settings = settings } |> computeSchema


mapSettings : (ProjectSettings -> ProjectSettings) -> Erd -> Erd
mapSettings transform erd =
    setSettings (transform erd.settings) erd
