module PagesComponents.App.Updates.PortMsg exposing (handlePortMsg)

import FileValue exposing (File)
import Libs.List as L
import Libs.Models exposing (FileContent, FileUrl)
import Libs.Task exposing (send)
import Models.Project exposing (ProjectSource, ProjectSourceContent(..), ProjectSourceId)
import PagesComponents.App.Models exposing (Model, Msg(..), SourceMsg(..))
import PagesComponents.App.Updates.Helpers exposing (decodeErrorToHtml)
import PagesComponents.App.Updates.Hotkey exposing (handleHotkey)
import Ports exposing (JsMsg(..), toastError, trackJsonError)
import Time


handlePortMsg : JsMsg -> Model -> Cmd Msg
handlePortMsg msg model =
    case msg of
        GotSizes sizes ->
            send (SizesChanged sizes)

        GotProjects ( errors, projects ) ->
            Cmd.batch (send (ProjectsLoaded projects) :: (errors |> List.concatMap (\( name, err ) -> [ toastError ("Unable to read project <b>" ++ name ++ "</b>:<br>" ++ decodeErrorToHtml err), trackJsonError "decode-project" err ])))

        GotLocalFile now projectId sourceId file content ->
            send (SourceMsg (FileLoaded now projectId (localSource now sourceId file) content Nothing))

        GotRemoteFile now projectId sourceId url content sample ->
            send (SourceMsg (FileLoaded now projectId (remoteSource now sourceId url content) content sample))

        GotHotkey hotkey ->
            Cmd.batch (handleHotkey model hotkey)

        Error err ->
            Cmd.batch [ toastError ("Unable to decode JavaScript message:<br>" ++ decodeErrorToHtml err), trackJsonError "js-message" err ]


localSource : Time.Posix -> ProjectSourceId -> File -> ProjectSource
localSource now id file =
    ProjectSource id (lastSegment file.name) (LocalFile file.name file.size file.lastModified) True now now


remoteSource : Time.Posix -> ProjectSourceId -> FileUrl -> FileContent -> ProjectSource
remoteSource now id url content =
    ProjectSource id (lastSegment url) (RemoteFile url (String.length content)) True now now


lastSegment : String -> String
lastSegment path =
    path |> String.split "/" |> List.filter (\p -> not (p == "")) |> L.last |> Maybe.withDefault path
