module PagesComponents.Projects.Id_.Updates.Sharing exposing (handleSharing)

import Conf
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project.ProjectStorage as ProjectStorage
import PagesComponents.Projects.Id_.Models exposing (Model, Msg(..), SharingMsg(..))
import PagesComponents.Projects.Id_.Models.EmbedKind as EmbedKind
import PagesComponents.Projects.Id_.Models.EmbedMode as EmbedMode
import Ports
import Services.Lenses exposing (mapSharingM, setSharing)
import Track


handleSharing : SharingMsg -> Model -> ( Model, Cmd Msg )
handleSharing msg model =
    case msg of
        SOpen ->
            ( model
                |> setSharing
                    (Just
                        (model.erd
                            |> Maybe.filter (\erd -> erd.project.storage == ProjectStorage.Cloud)
                            |> Maybe.mapOrElse
                                (\erd ->
                                    { id = Conf.ids.sharingDialog
                                    , kind = EmbedKind.EmbedProjectId
                                    , content = erd.project.id
                                    , layout = erd.usedLayout |> Maybe.withDefault ""
                                    , mode = EmbedMode.default
                                    }
                                )
                                { id = Conf.ids.sharingDialog
                                , kind = EmbedKind.EmbedProjectUrl
                                , content = ""
                                , layout = model.erd |> Maybe.andThen .usedLayout |> Maybe.withDefault ""
                                , mode = EmbedMode.default
                                }
                        )
                    )
            , Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.sharingDialog), Ports.track Track.openSharing ]
            )

        SClose ->
            ( model |> setSharing Nothing, Cmd.none )

        SKindUpdate kind ->
            ( model |> mapSharingM (\s -> { s | kind = kind, content = "" }), Cmd.none )

        SContentUpdate content ->
            ( model |> mapSharingM (\s -> { s | content = content }), Cmd.none )

        SLayoutUpdate layout ->
            ( model |> mapSharingM (\s -> { s | layout = layout }), Cmd.none )

        SModeUpdate mode ->
            ( model |> mapSharingM (\s -> { s | mode = mode }), Cmd.none )
