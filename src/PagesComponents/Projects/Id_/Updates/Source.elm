module PagesComponents.Projects.Id_.Updates.Source exposing (addRelation)

import Libs.List as List
import Libs.Task as T
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Relation as Relation
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.TableId as TableId
import PagesComponents.Projects.Id_.Models exposing (Msg, toastInfo)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import Ports
import Services.Lenses exposing (mapRelations)


addRelation : ColumnRef -> ColumnRef -> Erd -> ( Erd, Cmd Msg )
addRelation src ref erd =
    case erd.sources |> List.find (\s -> s.kind == UserDefined) of
        Just source ->
            ( erd |> Erd.mapSource source.id (mapRelations (\relations -> relations ++ [ Relation.virtual src ref source.id ]))
            , T.send (toastInfo ("Relation " ++ TableId.show src.table ++ " → " ++ TableId.show ref.table ++ " added to " ++ source.name ++ " source."))
            )

        Nothing ->
            ( erd, Ports.getSourceId src ref )
