module PagesComponents.Projects.Id_.Updates.Source exposing (addRelation)

import Dict
import Libs.List as List
import Libs.Task as T
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Relation as Relation
import Models.Project.Source as Source
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.TableId as TableId
import PagesComponents.Projects.Id_.Models exposing (Msg(..))
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import Services.Lenses exposing (mapRelations)
import Services.Toasts as Toasts
import Time


addRelation : Time.Posix -> ColumnRef -> ColumnRef -> Erd -> ( Erd, Cmd Msg )
addRelation now src ref erd =
    case erd.sources |> List.find (\s -> s.kind == UserDefined) of
        Just source ->
            ( erd |> Erd.mapSource source.id (mapRelations (\relations -> relations ++ [ Relation.virtual src ref source.id ]))
            , Toasts.info Toast ("Relation " ++ TableId.show src.table ++ " → " ++ TableId.show ref.table ++ " added to " ++ source.name ++ " source.")
            )

        Nothing ->
            let
                ( sourceId, seed ) =
                    SourceId.random erd.seed
            in
            ( { erd | seed = seed }
                |> Erd.mapSources (\sources -> sources ++ [ Source.user sourceId Dict.empty [] now ])
            , Cmd.batch [ Toasts.info Toast "Created a user source to add the relation.", T.send (CreateRelation src ref) ]
            )
