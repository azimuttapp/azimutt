module PagesComponents.Projects.Id_.Updates.Source exposing (createRelation, createUserSource)

import Conf
import Dict
import Libs.List as List
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source as Source exposing (Source)
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.SourceName exposing (SourceName)
import Models.Project.TableId as TableId
import PagesComponents.Projects.Id_.Models exposing (Msg(..))
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import Services.Toasts as Toasts
import Time


createUserSource : Time.Posix -> SourceName -> Erd -> Erd
createUserSource now name erd =
    addUserSource now name erd |> Tuple.first


addUserSource : Time.Posix -> SourceName -> Erd -> ( Erd, Source )
addUserSource now name erd =
    let
        ( sourceId, seed ) =
            SourceId.random erd.seed

        source : Source
        source =
            Source.amlEditor sourceId name Dict.empty [] now
    in
    ( { erd | seed = seed } |> Erd.mapSources (\sources -> sources ++ [ source ]), source )


createRelation : Time.Posix -> ColumnRef -> ColumnRef -> Erd -> ( Erd, Cmd Msg )
createRelation now src ref erd =
    case erd.sources |> List.find (\s -> s.kind == AmlEditor && s.name == Conf.constants.virtualRelationSourceName) of
        Just source ->
            ( erd |> addRelation now erd.settings.defaultSchema source src ref
            , Toasts.info Toast ("Relation " ++ TableId.show erd.settings.defaultSchema src.table ++ " → " ++ TableId.show erd.settings.defaultSchema ref.table ++ " added to " ++ source.name ++ " source.")
            )

        Nothing ->
            ( erd |> addUserSource now Conf.constants.virtualRelationSourceName |> (\( e, s ) -> e |> addRelation now erd.settings.defaultSchema s src ref)
            , Toasts.info Toast ("Created " ++ Conf.constants.virtualRelationSourceName ++ " source to add the relation.")
            )


addRelation : Time.Posix -> SchemaName -> Source -> ColumnRef -> ColumnRef -> Erd -> Erd
addRelation now defaultSchema source src ref erd =
    erd |> Erd.mapSource source.id (Source.addRelation now defaultSchema src ref)
