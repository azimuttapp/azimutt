module PagesComponents.Projects.Id_.Models.Erd exposing (Erd, create, currentLayout, getColumn, isShown, mapCurrentLayout, mapCurrentLayoutCmd, mapSettings, mapSource, mapSources, setSettings, setSources, unpack)

import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Time as Time
import Models.Project as Project exposing (Project)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation exposing (Relation)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdLayout as ErdLayout exposing (ErdLayout)
import PagesComponents.Projects.Id_.Models.ErdRelation as ErdRelation exposing (ErdRelation)
import PagesComponents.Projects.Id_.Models.ErdTable as ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableNotes as ErdTableNotes exposing (ErdTableNotes)
import PagesComponents.Projects.Id_.Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Random
import Services.Lenses exposing (mapLayoutsD, mapLayoutsDCmd)
import Time


type alias Erd =
    { seed : Random.Seed
    , project : ProjectInfo
    , tables : Dict TableId ErdTable
    , relations : List ErdRelation
    , relationsByTable : Dict TableId (List Relation)
    , layouts : Dict LayoutName ErdLayout
    , currentLayout : LayoutName
    , notes : Dict TableId ErdTableNotes
    , sources : List Source
    , settings : ProjectSettings
    }


create : Random.Seed -> Project -> Erd
create seed project =
    let
        relationsByTable : Dict TableId (List Relation)
        relationsByTable =
            buildRelationsByTable project.relations
    in
    { seed = seed
    , project = ProjectInfo.create project
    , tables = project.tables |> Dict.map (\id -> ErdTable.create project.tables (relationsByTable |> Dict.getOrElse id []))
    , relations = project.relations |> List.map (ErdRelation.create project.tables)
    , relationsByTable = relationsByTable
    , layouts = project.layouts |> Dict.map (\_ -> ErdLayout.create relationsByTable)
    , currentLayout = project.usedLayout
    , notes = ErdTableNotes.createAll project.notes
    , sources = project.sources
    , settings = project.settings
    }
        |> computeSchema


unpack : Erd -> Project
unpack erd =
    { id = erd.project.id
    , name = erd.project.name
    , sources = erd.sources
    , tables = erd.tables |> Dict.map (\_ -> ErdTable.unpack)
    , relations = erd.relations |> List.map ErdRelation.unpack
    , notes = ErdTableNotes.unpackAll erd.notes
    , usedLayout = erd.currentLayout
    , layouts = erd.layouts |> Dict.map (\_ -> ErdLayout.unpack)
    , settings = erd.settings
    , storage = erd.project.storage
    , createdAt = erd.project.createdAt
    , updatedAt = erd.project.updatedAt
    }


currentLayout : Erd -> ErdLayout
currentLayout erd =
    erd.layouts |> Dict.getOrElse erd.currentLayout (ErdLayout.empty Time.zero)


mapCurrentLayout : Time.Posix -> (ErdLayout -> ErdLayout) -> Erd -> Erd
mapCurrentLayout now transform erd =
    erd |> mapLayoutsD erd.currentLayout (transform >> (\l -> { l | updatedAt = now }))


mapCurrentLayoutCmd : Time.Posix -> (ErdLayout -> ( ErdLayout, Cmd msg )) -> Erd -> ( Erd, Cmd msg )
mapCurrentLayoutCmd now transform erd =
    erd |> mapLayoutsDCmd erd.currentLayout (transform >> Tuple.mapFirst (\l -> { l | updatedAt = now }))


getColumn : ColumnRef -> Erd -> Maybe ErdColumn
getColumn ref erd =
    erd.tables |> Dict.get ref.table |> Maybe.andThen (\t -> t.columns |> Dict.get ref.column)


isShown : TableId -> Erd -> Bool
isShown table erd =
    erd |> currentLayout |> .tables |> List.memberBy .id table


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
    in
    { erd
        | tables = tables |> Dict.map (\id -> ErdTable.create tables (relationsByTable |> Dict.getOrElse id []))
        , relations = relations |> List.map (ErdRelation.create tables)
        , relationsByTable = relationsByTable
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
