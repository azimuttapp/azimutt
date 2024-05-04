module PagesComponents.Organization_.Project_.Models.Erd exposing (Erd, canChangeColor, canCreateGroup, canCreateLayout, canCreateMemo, canShowTables, create, currentLayout, defaultSchemaM, getColumn, getColumnPos, getLayoutTable, getOrganization, getOrganizationM, getProjectId, getProjectIdM, getProjectRef, getProjectRefM, getTable, isShown, mapCurrentLayout, mapCurrentLayoutT, mapCurrentLayoutTMWithTime, mapCurrentLayoutTWithTime, mapCurrentLayoutWithTime, mapIgnoredRelationsT, mapSettings, mapSource, mapSourceT, mapSources, mapSourcesT, setIgnoredRelations, setSettings, setSources, toSchema, unpack, viewportM, viewportToCanvas)

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
import Models.Project exposing (Project)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.ColumnRef exposing (ColumnRef, ColumnRefLike)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.Metadata exposing (Metadata)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation exposing (Relation)
import Models.Project.Schema exposing (Schema)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.ProjectRef exposing (ProjectRef)
import Models.Size as Size
import Models.UrlInfos exposing (UrlInfos)
import PagesComponents.Organization_.Project_.Models.Erd.RelationWithOrigin as RelationWithOrigin exposing (RelationWithOrigin)
import PagesComponents.Organization_.Project_.Models.Erd.TableWithOrigin as TableWithOrigin exposing (TableWithOrigin)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps
import PagesComponents.Organization_.Project_.Models.ErdCustomType as ErdCustomType exposing (ErdCustomType)
import PagesComponents.Organization_.Project_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.SuggestedRelation exposing (SuggestedRelation)
import PagesComponents.Organization_.Project_.Views.Modals.SchemaAnalysis.RelationMissing as RelationMissing
import Services.Lenses exposing (mapLayoutsD, mapLayoutsDT, mapLayoutsDTM)
import Set exposing (Set)
import Time


type alias Erd =
    { project : ProjectInfo
    , tables : Dict TableId ErdTable
    , relations : List ErdRelation
    , types : Dict CustomTypeId ErdCustomType
    , relationsByTable : Dict TableId (List ErdRelation)
    , ignoredRelations : Dict TableId (List ColumnPath)
    , layouts : Dict LayoutName ErdLayout
    , currentLayout : LayoutName
    , layoutOnLoad : String -- enum: "", "fit", "arrange"
    , tableRowsSeq : Int
    , metadata : Metadata
    , sources : List Source
    , settings : ProjectSettings
    }


create : Project -> Erd
create project =
    let
        ( ( tables, relations, types ), relationsByTable ) =
            computeSources project.settings project.sources project.ignoredRelations

        layout : LayoutName
        layout =
            (project.layouts |> Dict.get Conf.constants.defaultLayout |> Maybe.map (\_ -> Conf.constants.defaultLayout))
                |> Maybe.orElse (project.layouts |> Dict.keys |> List.sort |> List.head)
                |> Maybe.withDefault Conf.constants.defaultLayout
    in
    { project = ProjectInfo.fromProject project
    , tables = tables
    , relations = relations
    , types = types
    , relationsByTable = relationsByTable
    , ignoredRelations = project.ignoredRelations
    , layouts = project.layouts |> Dict.map (\_ -> ErdLayout.create relationsByTable)
    , currentLayout = layout
    , layoutOnLoad = ""
    , tableRowsSeq = project.tableRowsSeq
    , metadata = project.metadata
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
    , ignoredRelations = erd.ignoredRelations
    , metadata = erd.metadata
    , layouts = erd.layouts |> Dict.map (\_ -> ErdLayout.unpack)
    , tableRowsSeq = erd.tableRowsSeq
    , settings = erd.settings
    , storage = erd.project.storage
    , visibility = erd.project.visibility
    , version = erd.project.version
    , createdAt = erd.project.createdAt
    , updatedAt = erd.project.updatedAt
    }


toSchema : { s | tables : Dict TableId ErdTable, relations : List ErdRelation, types : Dict CustomTypeId ErdCustomType } -> Schema
toSchema source =
    { tables = source.tables |> Dict.map (\_ -> ErdTable.unpack)
    , relations = source.relations |> List.map ErdRelation.unpack
    , types = source.types |> Dict.map (\_ -> ErdCustomType.unpack)
    }


currentLayout : Erd -> ErdLayout
currentLayout erd =
    erd.layouts |> Dict.getOrElse erd.currentLayout (ErdLayout.empty Time.zero)


mapCurrentLayout : (ErdLayout -> ErdLayout) -> Erd -> Erd
mapCurrentLayout transform erd =
    erd |> mapLayoutsD erd.currentLayout transform


mapCurrentLayoutT : (ErdLayout -> ( ErdLayout, a )) -> Erd -> ( Erd, Maybe a )
mapCurrentLayoutT transform erd =
    erd |> mapLayoutsDT erd.currentLayout transform


mapCurrentLayoutWithTime : Time.Posix -> (ErdLayout -> ErdLayout) -> Erd -> Erd
mapCurrentLayoutWithTime now transform erd =
    erd |> mapLayoutsD erd.currentLayout (transform >> (\l -> { l | updatedAt = now }))


mapCurrentLayoutTWithTime : Time.Posix -> (ErdLayout -> ( ErdLayout, a )) -> Erd -> ( Erd, Maybe a )
mapCurrentLayoutTWithTime now transform erd =
    erd |> mapLayoutsDT erd.currentLayout (transform >> Tuple.mapFirst (\l -> { l | updatedAt = now }))


mapCurrentLayoutTMWithTime : Time.Posix -> (ErdLayout -> ( ErdLayout, Maybe a )) -> Erd -> ( Erd, Maybe a )
mapCurrentLayoutTMWithTime now transform erd =
    erd |> mapLayoutsDTM erd.currentLayout (transform >> Tuple.mapFirst (\l -> { l | updatedAt = now }))


getOrganization : Maybe OrganizationId -> Erd -> Organization
getOrganization urlOrganization erd =
    getOrganizationM urlOrganization (Just erd)


getOrganizationM : Maybe OrganizationId -> Maybe Erd -> Organization
getOrganizationM urlOrganization erd =
    let
        zero : Organization
        zero =
            Organization.zero
    in
    erd |> Maybe.andThen (.project >> .organization) |> Maybe.withDefault (urlOrganization |> Maybe.mapOrElse (\id -> { zero | id = id }) zero)


getProjectId : Maybe ProjectId -> Erd -> ProjectId
getProjectId urlProjectId erd =
    getProjectIdM urlProjectId (Just erd)


getProjectIdM : Maybe ProjectId -> Maybe Erd -> ProjectId
getProjectIdM urlProjectId erd =
    erd |> Maybe.map (.project >> .id) |> Maybe.orElse urlProjectId |> Maybe.withDefault ProjectId.zero


getProjectRef : UrlInfos -> Erd -> ProjectRef
getProjectRef urlInfos erd =
    getProjectRefM urlInfos (Just erd)


getProjectRefM : UrlInfos -> Maybe Erd -> ProjectRef
getProjectRefM urlInfos erd =
    { organization = erd |> getOrganizationM urlInfos.organization, id = erd |> getProjectIdM urlInfos.project }


canCreateLayout : Maybe Erd -> Bool
canCreateLayout erd =
    erd |> getOrganizationM Nothing |> .plan |> .layouts |> Maybe.all (\max -> max + 1 > Dict.size (erd |> Maybe.mapOrElse .layouts Dict.empty))


canCreateMemo : Maybe Erd -> Bool
canCreateMemo erd =
    erd |> getOrganizationM Nothing |> .plan |> .memos |> Maybe.all (\max -> max > List.length (erd |> Maybe.mapOrElse (currentLayout >> .memos) []))


canCreateGroup : Maybe Erd -> Bool
canCreateGroup erd =
    erd |> getOrganizationM Nothing |> .plan |> .groups |> Maybe.all (\max -> max > List.length (erd |> Maybe.mapOrElse (currentLayout >> .groups) []))


canChangeColor : Maybe Erd -> Bool
canChangeColor erd =
    erd |> getOrganizationM Nothing |> .plan |> .colors


canShowTables : Int -> Maybe Erd -> Bool
canShowTables nb erd =
    let
        layoutTables : Int
        layoutTables =
            erd |> Maybe.mapOrElse (currentLayout >> .tables >> List.length) 0
    in
    erd |> getOrganizationM Nothing |> .plan |> .layoutTables |> Maybe.all (\max -> layoutTables + nb <= max)


getTable : TableId -> Erd -> Maybe ErdTable
getTable tableId erd =
    erd.tables |> ErdTable.getTable erd.settings.defaultSchema tableId


getColumn : ColumnRef -> Erd -> Maybe ErdColumn
getColumn ref erd =
    erd |> getTable ref.table |> Maybe.andThen (ErdTable.getColumn ref.column)


getColumnPos : ColumnRef -> Erd -> Maybe Position.Canvas
getColumnPos ref erd =
    (currentLayout erd |> .tables)
        |> List.find (\t -> t.id == ref.table)
        |> Maybe.andThen (\t -> t.columns |> ErdColumnProps.getIndex ref.column |> Maybe.map (\i -> ( t.props, i )))
        |> Maybe.map
            (\( t, index ) ->
                (if t.collapsed then
                    { dx = (Size.extractCanvas t.size).width / 2
                    , dy = Conf.ui.table.headerHeight * 0.5
                    }

                 else
                    { dx = (Size.extractCanvas t.size).width / 2
                    , dy = Conf.ui.table.headerHeight + (Conf.ui.table.columnHeight * (0.5 + (index |> toFloat)))
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


computeSources : ProjectSettings -> List Source -> Dict TableId (List ColumnPath) -> ( ( Dict TableId ErdTable, List ErdRelation, Dict CustomTypeId ErdCustomType ), Dict TableId (List ErdRelation) )
computeSources settings sources ignoredRelations =
    let
        enabledSources : List Source
        enabledSources =
            sources |> List.filter .enabled

        tables : Dict TableId TableWithOrigin
        tables =
            enabledSources |> computeTables settings

        relations : List RelationWithOrigin
        relations =
            enabledSources |> computeRelations (tables |> Dict.keys |> Set.fromList)

        erdTypes : Dict CustomTypeId ErdCustomType
        erdTypes =
            enabledSources |> computeTypes

        suggestedRelations : Dict TableId (Dict ColumnPathStr (List SuggestedRelation))
        suggestedRelations =
            RelationMissing.compute ignoredRelations (tables |> Dict.map (\_ -> TableWithOrigin.unpack)) (relations |> List.map RelationWithOrigin.unpack)
                |> List.groupBy (\r -> r.src.table)
                |> Dict.mapValues (List.groupBy (\r -> r.src.column |> ColumnPath.toString))

        erdRelations : List ErdRelation
        erdRelations =
            relations |> List.map (ErdRelation.create tables)

        erdRelationsByTable : Dict TableId (List ErdRelation)
        erdRelationsByTable =
            buildRelationsByTable erdRelations

        erdTables : Dict TableId ErdTable
        erdTables =
            tables |> Dict.map (\id -> ErdTable.create settings.defaultSchema erdTypes (erdRelationsByTable |> Dict.getOrElse id []) (suggestedRelations |> Dict.getOrElse id Dict.empty))
    in
    ( ( erdTables, erdRelations, erdTypes ), erdRelationsByTable )


computeTables : ProjectSettings -> List Source -> Dict TableId TableWithOrigin
computeTables settings sources =
    sources
        |> List.map (\s -> s.tables |> Dict.filter (\_ -> shouldDisplayTable settings) |> Dict.map (\_ -> TableWithOrigin.create s))
        |> List.foldr (Dict.fuse TableWithOrigin.merge) Dict.empty


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


computeRelations : Set TableId -> List Source -> List RelationWithOrigin
computeRelations tables sources =
    sources
        |> List.map (\s -> s.relations |> List.filter (shouldDisplayRelation tables) |> List.map (RelationWithOrigin.create s))
        |> List.foldr (List.merge .id RelationWithOrigin.merge) []


shouldDisplayRelation : Set TableId -> Relation -> Bool
shouldDisplayRelation tables relation =
    (tables |> Set.member relation.src.table) && (tables |> Set.member relation.ref.table)


computeTypes : List Source -> Dict CustomTypeId ErdCustomType
computeTypes sources =
    sources
        |> List.map (\s -> s.types |> Dict.map (\_ -> ErdCustomType.create s))
        |> List.foldr (Dict.fuse ErdCustomType.merge) Dict.empty


buildRelationsByTable : List ErdRelation -> Dict TableId (List ErdRelation)
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
        { erd | sources = sources } |> recomputeSources


mapSources : (List Source -> List Source) -> Erd -> Erd
mapSources transform erd =
    setSources (transform erd.sources) erd


mapSourcesT : (List Source -> ( List Source, t )) -> Erd -> ( Erd, t )
mapSourcesT transform erd =
    transform erd.sources |> Tuple.mapFirst (\s -> setSources s erd)


mapSource : SourceId -> (Source -> Source) -> Erd -> Erd
mapSource id transform erd =
    setSources (List.mapBy .id id transform erd.sources) erd


mapSourceT : SourceId -> (Source -> ( Source, t )) -> Erd -> ( Erd, Maybe t )
mapSourceT id transform erd =
    List.mapByT .id id transform erd.sources |> Tuple.mapBoth (\sources -> setSources sources erd) List.head


setIgnoredRelations : Dict TableId (List ColumnPath) -> Erd -> Erd
setIgnoredRelations ignoredRelations erd =
    if erd.ignoredRelations == ignoredRelations then
        erd

    else
        { erd | ignoredRelations = ignoredRelations } |> recomputeSources


mapIgnoredRelationsT : (Dict TableId (List ColumnPath) -> ( Dict TableId (List ColumnPath), a )) -> Erd -> ( Erd, a )
mapIgnoredRelationsT transform erd =
    transform erd.ignoredRelations |> Tuple.mapFirst (\r -> setIgnoredRelations r erd)


setSettings : ProjectSettings -> Erd -> Erd
setSettings settings erd =
    if erd.settings == settings then
        erd

    else
        { erd | settings = settings } |> recomputeSources


mapSettings : (ProjectSettings -> ProjectSettings) -> Erd -> Erd
mapSettings transform erd =
    setSettings (transform erd.settings) erd


recomputeSources : Erd -> Erd
recomputeSources erd =
    -- When changing any input of `computeSources`, you need to re-compute them
    let
        ( ( tables, relations, types ), relationsByTable ) =
            computeSources erd.settings erd.sources erd.ignoredRelations
    in
    { erd | tables = tables, relations = relations, types = types, relationsByTable = relationsByTable }
