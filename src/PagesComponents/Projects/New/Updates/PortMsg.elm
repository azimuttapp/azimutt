module PagesComponents.Projects.New.Updates.PortMsg exposing (handleJsMsg)

import Libs.FileInput exposing (File)
import Libs.List as L
import Libs.Task as T
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.SourceInfo exposing (SourceInfo)
import PagesComponents.Projects.New.Models exposing (Msg(..))
import Ports exposing (JsMsg(..))


handleJsMsg : JsMsg -> Cmd Msg
handleJsMsg msg =
    case msg of
        GotLocalFile now projectId sourceId file content ->
            T.send (FileLoaded projectId (SourceInfo sourceId (lastSegment file.name) (localSource file) True Nothing now now) content)

        _ ->
            T.send Noop


localSource : File -> SourceKind
localSource file =
    LocalFile file.name file.size file.lastModified


lastSegment : String -> String
lastSegment path =
    path |> String.split "/" |> List.filter (\p -> not (p == "")) |> L.last |> Maybe.withDefault path
