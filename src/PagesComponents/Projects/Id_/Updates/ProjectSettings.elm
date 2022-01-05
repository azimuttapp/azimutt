module PagesComponents.Projects.Id_.Updates.ProjectSettings exposing (Model, handleProjectSettings)

import Libs.Task as T
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectSettingsModel, ProjectSettingsMsg(..))


type alias Model x =
    { x | settings : Maybe ProjectSettingsModel }


handleProjectSettings : ProjectSettingsMsg -> Model x -> ( Model x, Cmd Msg )
handleProjectSettings msg model =
    case msg of
        PSOpen ->
            ( { model | settings = Just () }, T.sendAfter 1 ModalOpen )

        PSClose ->
            ( { model | settings = Nothing }, Cmd.none )
