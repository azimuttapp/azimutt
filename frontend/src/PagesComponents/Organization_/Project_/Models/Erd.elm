module PagesComponents.Organization_.Project_.Models.Erd exposing (Erd, create, currentLayout, defaultSchemaM, getColumn, getColumnPos, getLayoutTable, getOrganization, getTable, isShown, mapCurrentLayout, mapCurrentLayoutCmd, mapCurrentLayoutWithTime, mapSettings, mapSource, mapSources, setSettings, setSources, unpack, viewportM, viewportToCanvas)

import Conf
import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Time as Time
import Models.Area as Area
import Models.ErdProps exposing (ErdProps)
import Models.Organization as Organization exposing (Organization)
import Models.OrganizationId exposing (OrganizationId)
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
import Models.Project.TableId exposing (TableId)
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
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
    , visibility = erd.project.visibility
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


getOrganization : Maybe OrganizationId -> Erd -> Organization
getOrganization urlOrganization erd =
    let
        free : Organization
        free =
            Organization.free
    in
    erd.project.organization |> Maybe.withDefault (urlOrganization |> Maybe.mapOrElse (\id -> { free | id = id }) free)


getTable : TableId -> Erd -> Maybe ErdTable
getTable ( schema, table ) erd =
    case erd.tables |> Dict.get ( schema, table ) of
        Just t ->
            Just t

        Nothing ->
            if schema == Conf.schema.empty then
                erd.tables |> Dict.get ( erd.settings.defaultSchema, table )

            else
                Nothing


getColumn : ColumnRef -> Erd -> Maybe ErdColumn
getColumn ref erd =
    erd |> getTable ref.table |> Maybe.andThen (\t -> t.columns |> Dict.get ref.column)


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


getLayoutTable : TableId -> Erd -> Maybe ErdTableLayout
getLayoutTable table erd =
    erd |> currentLayout |> .tables |> List.findBy .id table


isShown : TableId -> Erd -> Bool
isShown table erd =
    erd |> getLayoutTable table |> Maybe.isJust


defaultSchemaM : Maybe Erd -> SchemaName
defaultSchemaM erd =
    erd |> Maybe.mapOrElse (.settings >> .defaultSchema) Conf.schema.empty


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
