module PagesComponents.Organization_.Project_.Models.Erd exposing (Erd, create, currentLayout, defaultSchemaM, getColumn, getColumnPos, getTable, isShown, mapCurrentLayout, mapCurrentLayoutCmd, mapCurrentLayoutWithTime, mapSettings, mapSource, mapSources, setSettings, setSources, unpack, viewportM, viewportToCanvas)

import Conf
import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Time as Time
import Models.Area as Area
import Models.ErdProps exposing (ErdProps)
import Models.Position as Position
import Models.Project as Project exposing (Project)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableNotes as ErdTableNotes exposing (ErdTableNotes)
import Services.Lenses exposing (mapLayoutsD, mapLayoutsDCmd)
import Time


type alias Erd =
    { project : ProjectInfo
    , tables : Dict TableId ErdTable
    , relations : List ErdRelation
    , types : Dict CustomTypeId CustomType
    , relationsByTable : Dict TableId (List Relation)
    , layouts : Dict LayoutName ErdLayout
    , currentLayout : LayoutName
    , notes : Dict TableId ErdTableNotes
    , sources : List Source
    , settings : ProjectSettings
    }


create : Project -> Erd
create project =
    let
        ( ( tables, relations, types ), relationsByTable ) =
            computeSources project.settings project.sources
    in
    { project = ProjectInfo.fromProject project
    , tables = tables
    , relations = relations
    , types = types
    , relationsByTable = relationsByTable
    , layouts = project.layouts |> Dict.map (\_ -> ErdLayout.create relationsByTable)
    , currentLayout = project.usedLayout
    , notes = ErdTableNotes.createAll project.notes
    , sources = project.sources
    , settings = project.settings
    }


unpack : Erd -> Project
unpack erd =
    { organization = erd.project.organization
    , id = erd.project.id
    , slug = erd.project.slug
    , name = erd.project.name
    , description = erd.project.description
    , sources = erd.sources
    , tables = erd.tables |> Dict.map (\_ -> ErdTable.unpack)
    , relations = erd.relations |> List.map ErdRelation.unpack
    , types = erd.types
    , notes = ErdTableNotes.unpackAll erd.notes
    , usedLayout = erd.currentLayout
    , layouts = erd.layouts |> Dict.map (\_ -> ErdLayout.unpack)
    , settings = erd.settings
    , storage = erd.project.storage
    , version = erd.project.version
    , createdAt = erd.project.createdAt
    , updatedAt = erd.project.updatedAt
    }


currentLayout : Erd -> ErdLayout
currentLayout erd =
    erd.layouts |> Dict.getOrElse erd.currentLayout (ErdLayout.empty Time.zero)


mapCurrentLayout : (ErdLayout -> ErdLayout) -> Erd -> Erd
mapCurrentLayout transform erd =
    erd |> mapLayoutsD erd.currentLayout transform


mapCurrentLayoutWithTime : Time.Posix -> (ErdLayout -> ErdLayout) -> Erd -> Erd
mapCurrentLayoutWithTime now transform erd =
    erd |> mapLayoutsD erd.currentLayout (transform >> (\l -> { l | updatedAt = now }))


mapCurrentLayoutCmd : Time.Posix -> (ErdLayout -> ( ErdLayout, Cmd msg )) -> Erd -> ( Erd, Cmd msg )
mapCurrentLayoutCmd now transform erd =
    erd |> mapLayoutsDCmd erd.currentLayout (transform >> Tuple.mapFirst (\l -> { l | updatedAt = now }))


getColumn : ColumnRef -> Erd -> Maybe ErdColumn
getColumn ref erd =
    erd.tables |> Dict.get ref.table |> Maybe.andThen (\t -> t.columns |> Dict.get ref.column)


getColumnPos : ColumnRef -> Erd -> Maybe Position.Canvas
getColumnPos ref erd =
    (currentLayout erd |> .tables)
        |> List.find (\t -> t.id == ref.table)
        |> Maybe.andThen (\t -> t.columns |> List.zipWithIndex |> List.find (\( c, _ ) -> c.name == ref.column) |> Maybe.map (\( c, i ) -> ( t.props, c, i )))
        |> Maybe.map
            (\( t, _, index ) ->
                (if t.collapsed then
                    { dx = (Size.extractCanvas t.size).width / 2
                    , dy = Conf.ui.tableHeaderHeight * 0.5
                    }

                 else
                    { dx = (Size.extractCanvas t.size).width / 2
                    , dy = Conf.ui.tableHeaderHeight + (Conf.ui.tableColumnHeight * (0.5 + (index |> toFloat)))
                    }
                )
                    |> (\delta -> t.position |> Position.offGrid |> Position.moveCanvas delta)
            )


isShown : TableId -> Erd -> Bool
isShown table erd =
    erd |> currentLayout |> .tables |> List.memberBy .id table


defaultSchemaM : Maybe Erd -> SchemaName
defaultSchemaM erd =
    erd |> Maybe.mapOrElse (.settings >> .defaultSchema) Conf.schema.empty


getTable : String -> Erd -> Maybe ErdTable
getTable tableId erd =
    (erd.tables |> Dict.get (TableId.parse tableId))
        |> Maybe.orElse (erd.tables |> Dict.get (TableId.parseWith erd.settings.defaultSchema tableId))


viewportToCanvas : ErdProps -> CanvasProps -> Position.Viewport -> Position.Canvas
viewportToCanvas erdElem canvas pos =
    pos |> Position.viewportToCanvas erdElem.position canvas.position canvas.zoom


viewportM : ErdProps -> Maybe Erd -> Area.Canvas
viewportM erdElem erd =
    erd |> Maybe.mapOrElse (currentLayout >> .canvas >> CanvasProps.viewport erdElem) Area.zeroCanvas


computeSources : ProjectSettings -> List Source -> ( ( Dict TableId ErdTable, List ErdRelation, Dict CustomTypeId CustomType ), Dict TableId (List Relation) )
computeSources settings sources =
    let
        tables : Dict TableId Table
        tables =
            sources |> Project.computeTables settings

        relations : List Relation
        relations =
            sources |> Project.computeRelations tables

        types : Dict CustomTypeId CustomType
        types =
            sources |> Project.computeTypes

        relationsByTable : Dict TableId (List Relation)
        relationsByTable =
            buildRelationsByTable relations

        erdTables : Dict TableId ErdTable
        erdTables =
            tables |> Dict.map (\id -> ErdTable.create settings.defaultSchema tables types (relationsByTable |> Dict.getOrElse id []))

        erdRelations : List ErdRelation
        erdRelations =
            relations |> List.map (ErdRelation.create tables)
    in
    ( ( erdTables, erdRelations, types ), relationsByTable )


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
        let
            ( ( tables, relations, types ), relationsByTable ) =
                computeSources erd.settings sources
        in
        { erd | sources = sources, tables = tables, relations = relations, types = types, relationsByTable = relationsByTable }


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
        let
            ( ( tables, relations, types ), relationsByTable ) =
                computeSources settings erd.sources
        in
        { erd | settings = settings, tables = tables, relations = relations, types = types, relationsByTable = relationsByTable }


mapSettings : (ProjectSettings -> ProjectSettings) -> Erd -> Erd
mapSettings transform erd =
    setSettings (transform erd.settings) erd
