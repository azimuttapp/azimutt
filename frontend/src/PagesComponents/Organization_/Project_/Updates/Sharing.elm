module PagesComponents.Organization_.Project_.Updates.Sharing exposing (handleSharing)

import Conf
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Project.ProjectStorage as ProjectStorage
import PagesComponents.Organization_.Project_.Models exposing (Model, Msg(..), SharingMsg(..))
import PagesComponents.Organization_.Project_.Models.EmbedKind as EmbedKind
import PagesComponents.Organization_.Project_.Models.EmbedMode as EmbedMode
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
                            |> Maybe.filter (\erd -> erd.project.storage == ProjectStorage.Remote)
                            |> Maybe.mapOrElse
                                (\erd ->
                                    { id = Conf.ids.sharingDialog
                                    , kind = EmbedKind.EmbedProjectId
                                    , content = erd.project.id
                                    , layout = erd.currentLayout
                                    , mode = EmbedMode.default
                                    }
                                )
                                { id = Conf.ids.sharingDialog
                                , kind = EmbedKind.EmbedProjectUrl
                                , content = ""
                                , layout = model.erd |> Maybe.mapOrElse .currentLayout ""
                                , mode = EmbedMode.default
                                }
                        )
                    )
            , Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.sharingDialog), Track.openSharing model.erd |> Ports.track ]
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
