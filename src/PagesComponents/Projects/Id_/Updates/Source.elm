module PagesComponents.Projects.Id_.Updates.Source exposing (createRelation)

import Conf
import Libs.List as List
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Source as Source
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.TableId as TableId
import PagesComponents.Projects.Id_.Models exposing (Msg(..))
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import Random
import Services.Toasts as Toasts
import Time


createRelation : Time.Posix -> ColumnRef -> ColumnRef -> Erd -> ( Erd, Cmd Msg )
createRelation now src ref erd =
    case erd.sources |> List.find (\s -> s.kind == AmlEditor && s.name == Conf.constants.virtualRelationSourceName) of
        Just source ->
            ( erd |> Erd.mapSource source.id (Source.addRelation now erd.settings.defaultSchema src ref)
            , Toasts.info Toast ("Relation " ++ TableId.show erd.settings.defaultSchema src.table ++ " → " ++ TableId.show erd.settings.defaultSchema ref.table ++ " added to " ++ source.name ++ " source.")
            )

        Nothing ->
            ( erd
            , Cmd.batch
                [ SourceId.generator
                    |> Random.generate
                        (\sourceId ->
                            Source.aml sourceId Conf.constants.virtualRelationSourceName now
                                |> Source.addRelation now erd.settings.defaultSchema src ref
                                |> CreateUserSourceWithId
                        )
                , Toasts.info Toast ("Created " ++ Conf.constants.virtualRelationSourceName ++ " source to add the relation.")
                ]
            )
