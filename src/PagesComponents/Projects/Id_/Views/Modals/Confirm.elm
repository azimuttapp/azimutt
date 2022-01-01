module PagesComponents.Projects.Id_.Views.Modals.Confirm exposing (viewConfirm)

import Components.Molecules.Modal as Modal
import Conf
import Html.Styled exposing (Html)
import Libs.Task as T
import PagesComponents.Projects.Id_.Models exposing (Msg(..))
import Shared exposing (Confirm)


viewConfirm : Bool -> Confirm Msg -> Html Msg
viewConfirm opened confirm =
    Modal.confirm
        { id = Conf.ids.confirm
        , icon = confirm.icon
        , color = confirm.color
        , title = confirm.title
        , message = confirm.message
        , confirm = confirm.confirm
        , cancel = confirm.cancel
        , onConfirm = ModalClose (ConfirmAnswer True confirm.onConfirm)
        , onCancel = ModalClose (ConfirmAnswer False (T.send (Noop "confirm cancel")))
        }
        opened
