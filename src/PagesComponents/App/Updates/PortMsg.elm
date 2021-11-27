module PagesComponents.App.Updates.PortMsg exposing (handleJsMsg)

import Array
import Dict
import FileValue exposing (File)
import Libs.Json.Decode as D
import Libs.List as L
import Libs.Models exposing (FileContent)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Task exposing (send)
import Models.Project.Relation as Relation
import Models.Project.Source exposing (Source)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.SourceInfo exposing (SourceInfo)
import PagesComponents.App.Models exposing (Model, Msg(..), SourceMsg(..))
import PagesComponents.App.Updates.Hotkey exposing (handleHotkey)
import Ports exposing (JsMsg(..), toastError, trackJsonError)


handleJsMsg : JsMsg -> Model -> Cmd Msg
handleJsMsg msg model =
    case msg of
        GotSizes sizes ->
            send (SizesChanged sizes)

        GotProjects ( errors, projects ) ->
            Cmd.batch (send (ProjectsLoaded projects) :: (errors |> List.concatMap (\( name, err ) -> [ toastError ("Unable to read project <b>" ++ name ++ "</b>:<br>" ++ D.errorToHtml err), trackJsonError "decode-project" err ])))

        GotLocalFile now projectId sourceId file content ->
            send (SourceMsg (FileLoaded projectId (SourceInfo sourceId (lastSegment file.name) (localSource file) True Nothing now now) content))

        GotRemoteFile now projectId sourceId url content sample ->
            send (SourceMsg (FileLoaded projectId (SourceInfo sourceId (lastSegment url) (remoteSource url content) True sample now now) content))

        GotSourceId now sourceId src ref ->
            send (SourceMsg (CreateSource (Source sourceId "User" UserDefined Array.empty Dict.empty [ Relation.virtual src ref sourceId ] True Nothing now now) "Relation added to newly create <b>User</b> source."))

        GotHotkey hotkey ->
            Cmd.batch (handleHotkey model hotkey)

        Error err ->
            Cmd.batch [ toastError ("Unable to decode JavaScript message:<br>" ++ D.errorToHtml err), trackJsonError "js-message" err ]


localSource : File -> SourceKind
localSource file =
    LocalFile file.name file.size file.lastModified


remoteSource : FileUrl -> FileContent -> SourceKind
remoteSource url content =
    RemoteFile url (String.length content)


lastSegment : String -> String
lastSegment path =
    path |> String.split "/" |> List.filter (\p -> not (p == "")) |> L.last |> Maybe.withDefault path
