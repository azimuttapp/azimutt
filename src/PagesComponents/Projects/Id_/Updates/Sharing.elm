module PagesComponents.Projects.Id_.Updates.Sharing exposing (handleSharing)

import Conf
import Libs.Task as T
import PagesComponents.Projects.Id_.Models exposing (Model, Msg(..), SharingMsg(..))
import PagesComponents.Projects.Id_.Models.EmbedMode as EmbedMode
import Ports
import Services.Lenses exposing (mapSharingM, setSharing)
import Track


handleSharing : SharingMsg -> Model -> ( Model, Cmd Msg )
handleSharing msg model =
    case msg of
        SOpen ->
            ( model |> setSharing (Just { id = Conf.ids.sharingDialog, url = "", layout = model.erd |> Maybe.andThen .usedLayout |> Maybe.withDefault "", mode = EmbedMode.layout })
            , Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.sharingDialog), Ports.track Track.openSharing ]
            )

        SClose ->
            ( model |> setSharing Nothing, Cmd.none )

        SProjectUrlUpdate url ->
            ( model |> mapSharingM (\s -> { s | url = url }), Cmd.none )

        SLayoutUpdate layout ->
            ( model |> mapSharingM (\s -> { s | layout = layout }), Cmd.none )

        SModeUpdate mode ->
            ( model |> mapSharingM (\s -> { s | mode = mode }), Cmd.none )
