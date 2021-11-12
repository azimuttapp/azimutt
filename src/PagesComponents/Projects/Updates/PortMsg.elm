module PagesComponents.Projects.Updates.PortMsg exposing (handlePortMsg)

import Libs.Task exposing (send)
import PagesComponents.App.Updates.Helpers exposing (decodeErrorToHtml)
import PagesComponents.Projects.Models exposing (Model, Msg(..))
import Ports exposing (JsMsg(..), toastError, trackJsonError)


handlePortMsg : JsMsg -> Model -> Cmd Msg
handlePortMsg msg _ =
    case msg of
        GotProjects ( errors, projects ) ->
            Cmd.batch (send (ProjectsLoaded projects) :: (errors |> List.concatMap (\( name, err ) -> [ toastError ("Unable to read project <b>" ++ name ++ "</b>:<br>" ++ decodeErrorToHtml err), trackJsonError "decode-project" err ])))

        _ ->
            Cmd.none
