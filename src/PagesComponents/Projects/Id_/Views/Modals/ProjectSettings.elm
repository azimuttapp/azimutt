module PagesComponents.Projects.Id_.Views.Modals.ProjectSettings exposing (viewProjectSettings)

import Components.Molecules.Slideover as Slideover
import Conf
import Html.Styled exposing (Html, div)
import Html.Styled.Attributes exposing (css)
import Libs.Html.Styled.Attributes exposing (ariaHidden)
import Models.Project exposing (Project)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), ProjectSettingsModel, ProjectSettingsMsg(..))
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


viewProjectSettings : Bool -> Project -> ProjectSettingsModel -> Html Msg
viewProjectSettings opened _ _ =
    Slideover.slideover
        { id = Conf.ids.settings
        , title = "Project settings"
        , isOpen = opened
        , onClickClose = ModalClose (ProjectSettingsMsg PSClose)
        , onClickOverlay = ModalClose (ProjectSettingsMsg PSClose)
        }
        (div [ css [ Tw.absolute, Tw.inset_0, Tw.px_4, Bp.sm [ Tw.px_6 ] ] ]
            [ div [ css [ Tw.h_full, Tw.border_2, Tw.border_dashed, Tw.border_gray_200 ], ariaHidden True ]
                []
            ]
        )
