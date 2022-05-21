module PagesComponents.Projects.Id_.Updates.ProjectUpload exposing (Model, handleProjectUpload)

import Conf
import Libs.Task as T
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectUploadDialog, ProjectUploadMsg(..))
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import Ports
import Services.Lenses exposing (setUpload)
import Track


type alias Model x =
    { x
        | erd : Maybe Erd
        , upload : Maybe ProjectUploadDialog
    }


handleProjectUpload : ProjectUploadMsg -> Model x -> ( Model x, Cmd Msg )
handleProjectUpload msg model =
    case msg of
        PUOpen ->
            ( model |> setUpload (Just { id = Conf.ids.sharingDialog })
            , Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.sharingDialog), Ports.track Track.openUpload ]
            )

        PUClose ->
            ( model |> setUpload Nothing, Cmd.none )
