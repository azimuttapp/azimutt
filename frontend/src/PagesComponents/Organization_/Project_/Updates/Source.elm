module PagesComponents.Organization_.Project_.Updates.Source exposing (createRelations)

import Conf
import Libs.List as List
import Libs.Task as T
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Source as Source
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.TableId as TableId
import PagesComponents.Organization_.Project_.Models exposing (Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import Random
import Services.Toasts as Toasts
import Time


createRelations : Time.Posix -> List { src : ColumnRef, ref : ColumnRef } -> Erd -> ( Erd, Cmd Msg )
createRelations now rels erd =
    case erd.sources |> List.find (\s -> s.kind == AmlEditor && s.name == Conf.constants.virtualRelationSourceName) of
        Just source ->
            ( erd |> Erd.mapSource source.id (Source.addRelations now rels)
            , case rels of
                [] ->
                    "No relation to add." |> Toasts.info |> Toast |> T.send

                { src, ref } :: [] ->
                    "Relation " ++ TableId.show erd.settings.defaultSchema src.table ++ " → " ++ TableId.show erd.settings.defaultSchema ref.table ++ " added to " ++ source.name ++ " source." |> Toasts.info |> Toast |> T.send

                _ ->
                    (rels |> List.length |> String.fromInt) ++ " relations added to " ++ source.name ++ " source." |> Toasts.info |> Toast |> T.send
            )

        Nothing ->
            ( erd
            , Cmd.batch
                [ SourceId.generator |> Random.generate (Source.aml Conf.constants.virtualRelationSourceName now >> Source.addRelations now rels >> CreateUserSourceWithId)
                , "Created " ++ Conf.constants.virtualRelationSourceName ++ " source to add the relations." |> Toasts.info |> Toast |> T.send
                ]
            )
